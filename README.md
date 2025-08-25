# vespa-with-clojure
An attempt to run some Clojure code in Vespa container node

## Vespa sample applications - a generic request-response processing application

A modified code from [here](https://github.com/vespa-engine/sample-apps/tree/master/examples/generic-request-processing).

Prepare a special Vespa Docker with Clojure libs in the classpath:
```aiignore
docker build -f Dockerfile -t vespa-clojure-1 .
docker run --rm --name vespa --hostname vespa-container \
  --publish 0.0.0.0:8080:8080 --publish 0.0.0.0:19071:19071 \
  vespa-clojure-1
```

Try deploying:

```shell
mvn clean -DskipTests package && vespa deploy && sleep 2 && curl -s http://localhost:8080/processing/
```

Run request:
```shell
curl -s http://localhost:8080/processing/
```

The response body should look like this:
```json
{
  "datalist": [
    {
      "data": "Hello, services!"
    },
    {
      "data": "Hello from Clojure"
    },
    {
      "data": "Hello from Clojure static method"
    }
  ]
}
```

So, it runs. I'm not sure if this is the best approach but it works.

## The Clojure code

[Here](src/main/clojure/ai/vespa/examples/MyClojure.clj)

This sample code looks like this:
```clojure
(ns ai.vespa.examples.MyClojure
  (:gen-class
    :init init
    :methods [[foo [] String]
              ^{:static true} [data [] String]]
    :prefix "-"))

(defn -init []
  (println "Clojure defined class Constructor"))

(defn -foo [this] "Hello from Clojure")

(defn -data []
  "Hello from Clojure static method")
```

## Experimentation log


The main problem is this:
```text
[2024-12-17 12:19:26.854] ERROR   container        Container.com.yahoo.protect.Process  java.lang.Error handling request\nexception=\njava.lang.ExceptionInInitializerError
	at clojure.java.api.Clojure.<clinit>(Clojure.java:97)
	at ai.vespa.examples.ExampleProcessor.process(ExampleProcessor.java:42)
	at com.yahoo.processing.execution.Execution.process(Execution.java:112)
	at com.yahoo.processing.handler.AbstractProcessingHandler.handle(AbstractProcessingHandler.java:126)
	at com.yahoo.container.jdisc.ThreadedHttpRequestHandler.handleRequest(ThreadedHttpRequestHandler.java:87)
	at com.yahoo.container.jdisc.ThreadedRequestHandler$RequestTask.processRequest(ThreadedRequestHandler.java:191)
	at com.yahoo.container.jdisc.ThreadedRequestHandler$RequestTask.run(ThreadedRequestHandler.java:185)
	at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1136)
	at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:635)
	at java.base/java.lang.Thread.run(Thread.java:840)\nCaused by: java.io.FileNotFoundException: Could not locate clojure/core__init.class, clojure/core.clj or clojure/core.cljc on classpath.
	at clojure.lang.RT.load(RT.java:482)
	at clojure.lang.RT.load(RT.java:444)
	at clojure.lang.RT.<clinit>(RT.java:358)
	... 10 more\n
```

Clojure and OSGi:

- https://mvnrepository.com/artifact/com.theoryinpractise/clojure.osgi/1.12.2
- https://github.com/talios/clojure.osgi

Vespa bundle plugin docs:
- https://docs.vespa.ai/en/components/bundles.html#configuring-the-bundle-plugin

### Executable example

**Validate environment, should be minimum 4G:**

Refer to [Docker memory](https://docs.vespa.ai/en/operations-selfhosted/docker-containers.html#memory)
for details and troubleshooting:
<pre>
$ docker info | grep "Total Memory"
or
$ podman info | grep "memTotal"
</pre>

**Check-out, compile and run:**
<pre data-test="exec">
$ git clone --depth 1 https://github.com/vespa-engine/sample-apps.git
$ cd sample-apps/examples/generic-request-processing &amp;&amp; mvn clean package
$ docker run --detach --name vespa --hostname vespa-container \
  --publish 127.0.0.1:8080:8080 --publish 127.0.0.1:19071:19071 \
  vespaengine/vespa:8.568.7
</pre>

**Wait for the configserver to start:**
<pre data-test="exec" data-test-wait-for="200 OK">
$ curl -s --head http://localhost:19071/ApplicationStatus
</pre>

**Deploy the application:**
<pre data-test="exec" data-test-assert-contains="prepared and activated.">
$ curl --header Content-Type:application/zip --data-binary @target/application.zip \
  localhost:19071/application/v2/tenant/default/prepareandactivate
</pre>

**Wait for the application to start:**
<pre data-test="exec" data-test-wait-for="200 OK">
$ curl -s --head http://localhost:8080/ApplicationStatus
</pre>

**Test the application:**
<pre data-test="exec" data-test-assert-contains="Hello, services!">
$ curl -s http://localhost:8080/processing/
</pre>

**Shutdown and remove the container:**
<pre data-test="after">
$ docker rm -f vespa
</pre>

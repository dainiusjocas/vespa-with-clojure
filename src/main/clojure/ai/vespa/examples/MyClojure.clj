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

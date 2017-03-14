(asdf:defsystem :cl-seniverse-api
  :version "0.0.2"
  :description "seniverse weather API for Common Lisp."
  :author "Muyinliu Xing <muyinliu@gmail.com>"
  :depends-on (:flexi-streams
               :ironclad
               :cl-base64
               :drakma)
  :components ((:static-file "cl-seniverse-api.asd")
               (:file "cl-seniverse-api")))

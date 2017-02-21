(asdf:defsystem :cl-thinkpage-api
  :version "0.0.1"
  :description "thinkpage weather API for Common Lisp."
  :author "Muyinliu Xing <muyinliu@gmail.com>"
  :depends-on (:flexi-streams
               :ironclad
               :cl-base64
               :drakma)
  :components ((:static-file "cl-thinkpage-api.asd")
               (:file "cl-thinkpage-api")))

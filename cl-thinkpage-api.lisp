;;;; cl-thinkpage-api.lisp
;;; Plese read this document http://www.thinkpage.cn/doc

(defpackage cl-thinkpage-api
  (:use :cl)
  (:nicknames :thinkpage-api :thinkpage)
  #+:sbcl (:shadow :defconstant)
  #+:sb-package-locks (:lock t)
  (:export #:*api-key*
           #:*user-id*
           #:*auth-ttl*
           #:+supported-language-list+
           
           ;; Weather APIs
           #:weather-now
           #:weather-daily
           #:weather-hourly
           #:weather-hourly-history
           #:weather-alarm
           
           ;; Air APIs
           #:air-now
           #:air-ranking
           #:air-daily
           #:air-hourly
           #:air-hourly-history

           ;; Life APIs
           #:life-suggestion
           #:life-chinese-calendar
           #:life-driving-restriction

           ;; Geo APIs
           #:geo-sun
           #:geo-moon

           ;; Location APIs
           #:location-search))

(in-package :cl-thinkpage-api)

(defmacro defconstant (name value &optional doc)
  "Make sure VALUE is evaluated only once \(to appease SBCL)."
  `(cl:defconstant ,name (if (boundp ',name) (symbol-value ',name) ,value)
     ,@(when doc (list doc))))

;; User information
(defvar *api-key* nil)       ;; Please use your own API key
(defvar *user-id* nil)       ;; Please use your own User ID

(defvar *auth-ttl* 1800) ;; second

;; Supported language list
(defconstant +supported-language-list+
  '("zh-Hans" "zh-Hant" "en" "ja" "de" "fr" "es" "pt" "hi" "id" "ru" "th" "ar"))

;; APIs common URL head
(defvar *api-url-head* "https://api.thinkpage.cn/v3")

;; Weather APIs
(defvar *api-weather-now-uri* "/weather/now.json"
  "天气实况")
(defvar *api-weather-daily-uri* "/weather/daily.json"
  "逐日天气预报和昨日天气")
(defvar *api-weather-hourly-uri* "/weather/hourly.json"
  "24小时逐小时天气预报（付费接口）")
(defvar *api-weather-hourly-history-uri* "/weather/hourly_history.json"
  "过去24小时历史天气（付费接口）")
(defvar *api-weather-alarm-uri* "/weather/alarm.json"
  "气象灾害预警（付费接口）")

;; Air APIs
(defvar *api-air-now-uri* "/air/now.json"
  "空气质量实况（付费接口）")
(defvar *api-air-ranking-uri* "/air/ranking.json"
  "空气质量实况城市排行（付费接口）")
(defvar *api-air-daily-uri* "/air/daily.json"
  "逐日空气质量预报（付费接口) ")
(defvar *api-air-hourly-uri* "/air/hourly.json"
  "逐小时空气质量预报（付费接口）")
(defvar *api-air-hourly-history-uri* "/air/hourly_history.json"
  "过去24小时历史空气质量（付费接口）")

;; Life APIs
(defvar *api-life-suggestion-uri* "/life/suggestion.json"
  "生活指数")
(defvar *api-life-chinese-calendar-uri* "/life/chinese_calendar.json"
  "农历、节气、生肖（付费接口）")
(defvar *api-life-driving-restriction-uri* "/life/driving_restriction.json"
  "机动车尾号限行（付费接口）")

;; Geo APIs
(defvar *api-geo-sun-uri* "/geo/sun.json"
  "日出日落（付费接口）")
(defvar *api-geo-moon-uri* "/geo/moon.json"
  "月出月落和月相（付费接口）")

;; Location APIs
(defvar *api-location-search-uri* "/location/search.json"
  "城市搜索")

;; Time utilities
(defvar *universal-time-diff-unix-time* 2208988800)

(defun universal-time->unix-time (universal-time)
  (- universal-time *universal-time-diff-unix-time*))

(defun unix-time->universal-time (unix-time)
  (+ unix-time *universal-time-diff-unix-time*))

(defun request (api-uri &key (auth-ttl *auth-ttl*)
                                (api-key *api-key*) (user-id *user-id*)
                                (api-url-head *api-url-head*)
                                location language unit scope
                                parameters)
  "A common function for request thinkpage API in secure way.
Note: parameters is an alist for http-request."
  ;; Check api-key & user-id
  (restart-case
      (unless api-key
        (error "api-key can NOT be nill."))
    (use-value (value)
      :report (lambda (stream)
                (format stream "Use another api-key instead."))
      :interactive (lambda ()
                     (format *query-io* "Enter api-key: ")
                     (finish-output *query-io*)
                     (list (read-line *query-io*)))
      (setf *api-key* value
            api-key value)))
  (restart-case
      (unless user-id
        (error "user-id can NOT be nill."))
    (use-value (value)
      :report (lambda (stream)
                (format stream "Use another user-id instead."))
      :interactive (lambda ()
                     (format *query-io* "Enter user-id: ")
                     (finish-output *query-io*)
                     (list (read-line *query-io*)))
      (setf *user-id* value
            user-id value)))
  
  ;; Check language
  (when language
    (assert (find language +supported-language-list+ :test #'equal)))
  
  ;; Deal with parameters
  (when parameters
    (setf parameters
          (loop for (key . value) in parameters
             when value collect (cons key
                                      (if (stringp value)
                                          value
                                          (write-to-string value))))))
  (let* ((unix-time (universal-time->unix-time (get-universal-time)))
         (string (format nil "ts=~A&ttl=~A&uid=~A"
                         unix-time
                         auth-ttl
                         user-id))
         (string-vector (flex:string-to-octets string :external-format :utf-8))
         (key-vector (flex:string-to-octets api-key :external-format :utf-8))
         (hmac (ironclad:make-hmac key-vector 'ironclad:sha1))
         (signature (progn
                      (ironclad:update-hmac hmac string-vector)
                      (base64:usb8-array-to-base64-string
                       (ironclad:hmac-digest hmac))))
         (request-url (format nil "~A~A" api-url-head api-uri)))
    (multiple-value-bind (data status-code)
        (drakma:http-request request-url
                             :parameters (append (list (cons "ts"  (write-to-string unix-time))
                                                       (cons "ttl" (write-to-string auth-ttl))
                                                       (cons "uid" user-id)
                                                       (cons "sig" signature))
                                                 (when location
                                                   (list (cons "location" location)))
                                                 (when language
                                                   (list (cons "language" language)))
                                                 (when unit
                                                   (list (cons "unit" unit)))
                                                 (when scope
                                                   (list (cons "scope" scope)))
                                                 parameters) 
                             :additional-headers '(("Accept-Encoding" . ""))
                             :external-format-out :utf-8
                             :external-format-in  :utf-8
                             :user-agent "")
      (values (flex:octets-to-string data :external-format :utf-8)
              status-code))))

(defun weather-now (location &key language unit)
  "天气实况
获取指定城市的天气实况。付费用户可获取全部数据，免费用户只返回天气现象文字、代码和气温3项数据。注：中国城市暂不支持云量和露点温度。"
  (request *api-weather-now-uri*
           :location location
           :language language
           :unit unit))

(defun weather-daily (location &key language unit start days)
  "逐日天气预报和昨日天气
获取指定城市未来最多15天每天的白天和夜间预报，以及昨日的历史天气。付费用户可获取全部数据，免费用户只返回3天天气预报。"
  (request *api-weather-daily-uri*
           :location location
           :language language
           :unit unit
           :parameters (list (cons "start" start)
                             (cons "days"  days))))

(defun weather-hourly (location &key language unit start hours)
  "24小时逐小时天气预报（付费接口）
获取指定城市未来最多24小时的逐小时天气预报，支持全球城市。"
  (request *api-weather-hourly-uri*
           :location location
           :language language
           :unit unit
           :parameters (list (cons "start" start)
                             (cons "hours" hours))))

(defun weather-hourly-history (location &key language unit)
  "过去24小时历史天气（付费接口）
获取指定城市过去24小时逐小时的历史天气。"
  (request *api-weather-hourly-history-uri*
           :location location
           :language language
           :unit unit))

(defun weather-alarm (location &key language unit)
  "气象灾害预警（付费接口）
获取当前所有城市或指定城市的气象灾害预警信息。当前城市无预警信息时返回值为空，请做好空值处理。"
  (request *api-weather-alarm-uri*
           :location location
           :language language
           :unit unit))

(defun air-now (location &key language scope)
  "空气质量实况（付费接口）
获取指定城市的AQI、PM2.5、PM10、一氧化碳、二氧化氮、臭氧等空气质量信息。"
  (request *api-air-now-uri*
           :location location
           :language language
           :scope scope))

(defun air-ranking (&key language)
  "空气质量实况城市排行（付费接口）
获取全国城市空气质量AQI排行榜。"
  (request *api-air-ranking-uri*
           :language language))

(defun air-daily (location &key language days)
  "逐日空气质量预报（付费接口) 
获取指定城市未来最多7天的逐日AQI预报。"
  (request *api-air-daily-uri*
           :location location
           :language language
           :parameters (list (cons "days"  days))))

(defun air-hourly (location &key language days)
  "逐小时空气质量预报（付费接口）
获取指定城市未来最多7天的逐小时AQI预报。"
  (request *api-air-hourly-uri*
           :location location
           :language language
           :parameters (list (cons "days"  days))))

(defun air-hourly-history (location &key language scope)
  "过去24小时历史空气质量（付费接口）
获取指定城市过去24小时逐小时的AQI、PM2.5、PM10、一氧化碳、二氧化氮、臭氧等空气质量信息。"
  (request *api-air-hourly-history-uri*
           :location location
           :language language
           :parameters (list (cons "scope"  scope))))

(defun life-suggestion (location &key language)
  "生活指数
获取指定城市的基本、交通、生活、运动、健康5大类共27项生活指数，仅支持中国城市。付费用户可获取全部数据; 免费用户只返回6项基本类生活指数，且只有brief，没有details。"
  (request *api-life-suggestion-uri*
           :location location
           :language language))

(defun life-chinese-calendar (&key start days)
  "农历、节气、生肖（付费接口）
查询任何一个公历日期对应的农历日期、农历传统节假日、二十四节气、天干地支纪年纪月纪日、及生肖属相。"
  (request *api-life-chinese-calendar-uri*
           :parameters (list (cons "start" start)
                             (cons "days"  days))))

(defun life-driving-restriction (location)
  "机动车尾号限行（付费接口）
查询北京、天津、哈尔滨、成都、杭州、贵阳、长春、兰州8个城市的今天、明天和后天的机动车尾号限行数据。"
  (request *api-life-driving-restriction-uri*
           :location location))

(defun geo-sun (location &key language start days)
  "日出日落（付费接口）
查询全球各地最多15天的日出日落时间。"
  (request *api-geo-sun-uri*
           :location location
           :language language
           :parameters (list (cons "start" start)
                             (cons "days"  days))))

(defun geo-moon (location &key language start days)
  "月出月落和月相（付费接口）
查询全球各地最多15天的月出月落时间和月相。"
  (request *api-geo-moon-uri*
           :location location
           :language language
           :parameters (list (cons "start" start)
                             (cons "days"  days))))

(defun location-search (q &key language limit offset)
  "城市搜索
根据城市ID、中文、英文、拼音、IP、经纬度搜索匹配的城市。"
  (request *api-location-search-uri*
           :language language
           :parameters (list (cons "q" q)
                             (cons "limit" limit)
                             (cons "offset" offset))))


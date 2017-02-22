# cl-thinkpage-api
cl-thinkpage-api is a Common Lisp SDK of
[thinkpage API](http://www.thinkpage.cn/doc) to get weather
information(include air information).

Note: Some of the API is NOT free.

## License
Copyright(c) 2017 Muyinliu Xing Released under the ISC License.

## Dependencies
Relax, usually Quicklisp will download all these packages for you :)

* flexi-streams
* ironclad
* cl-base64
* drakma

## Install and load with QuickLisp
In shell:
```shell
git clone https://github.com/muyinliu/cl-thinkpage-api.git
cp -r cl-thinkpage-api ~/quicklisp/local-projects/cl-thinkpage-api
```

Then in Common Lisp:
```lisp
(ql:quickload 'cl-thinkpage-api)
```

## Usage
Note: Please use your own `*api-key*` and `*user-id*` comes from [thinkpage](http://www.thinkpage.cn/), for example:
```lisp
(setf *api-key* "your-api-key")
(setf *user-id* "your-user-id")
```

### Get current weather information
```lisp
(thinkpage:weather-now "beijing")
```

Result example:
```
"{\"results\":[{\"location\":{\"id\":\"WX4FBXXFKE4F\",\"name\":\"北京\",\"country\":\"CN\",\"path\":\"北京,北京,中国\",\"timezone\":\"Asia/Shanghai\",\"timezone_offset\":\"+08:00\"},\"now\":{\"text\":\"雨夹雪\",\"code\":\"20\",\"temperature\":\"0\",\"feels_like\":\"-1\",\"pressure\":\"1023\",\"humidity\":\"70\",\"visibility\":\"3.1\",\"wind_direction\":\"东南\",\"wind_direction_degree\":\"121\",\"wind_speed\":\"6.48\",\"wind_scale\":\"2\",\"clouds\":\"\",\"dew_point\":\"\"},\"last_update\":\"2017-02-21T15:55:00+08:00\"}]}"
200
```

Note: More result example should check directory `/result-examples/`
and [thinkpage API Document](http://www.thinkpage.cn/doc)

Note: More function please read file **cl-thinkpage-api.lisp**


## More
Welcome to reply.

lempdock-deploy
===

Một bộ script để auto deploy những project cuối môn của các học viên của tôi tại CodeGym. Docker composer được
bốc sang từ thành quả sau khi ghi chép ở lọat bài [code laravel với docker][laradock].

Hướng dẫn
---

Bạn phải có docker cli và docker-compose cli để chạy dc script này.

Script này được thiết kế họat động với firewalld, sửa kỹ nếu bạn không dùng firewalld hoặc đang dùng thứ khác 
(iptable?).

### Up

```bash

$ cd 
$ git clone https://github.com/binhsonnguyen/lempdock-deploy.git
$ cd lempdock-deploy
lempdock-deploy $ ./deploy.sh <clonable_link.git>
#examp: $ ./deploy.sh https://github.com/abc/xyz-project.git

```

### Down

```bash
lempdock-deploy $ ls
4573/          compose/       down.sh        .gitignore     php7-prebuild/
lempdock-deploy $ ./down.sh 4573

```

[laradock]: http://binhsonnguyen.com/2017/09/08/laradock.html
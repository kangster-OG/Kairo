@echo off
curl "http://127.0.0.1:8081/index.bundle?platform=android&dev=true&hot=false&lazy=true" -o bundle-response.tmp

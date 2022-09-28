# Speed tester scripts

In this repository collected few scripts which allow to measure own tests between your hosts.

# Aditional app
For easy use, included free portable webserver (Apache, MySQL, PHP 5.4.17, phpMyAdmin)


# How its works

Before start using you have to load all functions to the powershell session:

```
. .\Speed-Testers.ps1
```

after loadins all functions, you can use them:

## Test-SpeedSamba

```
Test-SpeedSamba -source C:\50MB.zip -target \\server\shared\test\50MB.zip
```

## Test-SpeedSambaWithCount

```
Test-SpeedSamba -source C:\50MB.zip -target \\server\shared\test\50MB.zip -count 10
```

## Test-SpeedWeb
```
Test-SpeedWeb -target http://webserver:8080/50MB.zip
```

## Test-SpeedWebWithCount
```
Test-SpeedWeb -target http://webserver:8080/50MB.zip -count 10
```

## Test-SpeedIperf3
```
Test-SpeedIperf3
```
or
```
Test-SpeedIperf3 -target serverHost
```

## Test-SpeedTest
This is powershell based SpeedTest
```
Test-SpeedTest
```
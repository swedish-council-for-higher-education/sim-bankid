# sim-bankid

 Simulate BankId for performance testing.

## Build

`./mvnw package`

## Run

```bash
   docker run -it --rm \
   -p 8080:8080
   -e BANKID_ITERATIONS=3 \
   -e BANKID_CALL_DELAY_DURATION=PT1S
   sim-bankid
```
Load personal numbers from file before starting the test, see `etc/personal-numbers.json` for file format.

```bash
curl --header 'Content-Type: multipart/form-data' -F 'file=@etc/personal-numbers.json' 'http://localhost:8080/admin/pnr'
```

## Test & Usage

See [VS Rest client](etc/bankid.http)

## Check number of calls

```bash
curl -s http://localhost:8080/q/metrics | grep bankid
```

# Ports

* 8080 - The HTTP port.
* 8787 - Java remote debugging port.

# Environment variables

## Mandatory

-

## Optional

`JAVA_OPTS` - Argument passed to the jvm.

`BANKID_CALL_DELAY_DURATION` - Delay each call with the specified duration, example for 1 second specify "PT1S". Default value is "PT0S" (i.e. no delay).

`BANKID_ITERATIONS` - Stay in the "hintCode": "outstandingTransaction" state for n number of calls. Default value is 1.





import httpclient

let pUrl = "http://127.0.0.1"
let pPort = "8118"
let urlProxy = pUrl & ":" & pPort
echo "urlProxy:", urlProxy
let p = newProxy(urlProxy)
let c = newHttpClient(proxy = p, timeout = 120_000)
let r = c.getContent("https://www.dasoertliche.de/?zvo_ok=0&ci=63549+Ronneburg&st=Am+Schmiedeberg&radius=0&form_name=search_nat_ext")
echo "r:", r
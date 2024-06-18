import os, httpclient
import times
import asyncdispatch
import threadpool

type
  LinkCheck = ref object
    link: string
    state: bool

proc decodeLink(link: string): LinkCheck =
  var client = newHttpClient()
  try:
    return LinkCheck(link: link, state: client.get(link).code == Http200)
  except:
    return LinkCheck(link: link, state: false)

proc sequentialLinksChecker(links: seq[string]): void =
  for index, link in links:
    if link != "":
      let result = decodeLink(link)
      echo result.link, " is ", result.state

proc decodeLinkAsync(link: string): Future[LinkCheck] {.async.} =
  var client = newAsyncHttpClient()
  let future = client.get(link)
  yield future
  if future.failed:
    return LinkCheck(link: link, state: false)
  else:
    let resp = future.read()
    return LinkCheck(link: link, state: resp.code == Http200)

proc decodeLinksAsync(links: seq[string]) {.async.} =
  var futures = newSeq[Future[LinkCheck]]();
  for index, link in links:
    if link != "":
      futures.add(decodeLinkAsync(link))
  let done = await all(futures)
  for x in done:
    echo x.link, " is ", x.state


proc decodeLinkParallel(link: string): LinkCheck {.thread.} =
  var client = newHttpClient()
  try:
    return LinkCheck(link: link, state: client.get(link).code == Http200)
  except:
    return LinkCheck(link: link, state: false)

proc paralelLinkCycle(links: seq[string]): void =
  var pool = newSeq[FlowVar[LinkCheck]]()
  for index, link in links:
    pool.add(spawn decodeLinkParallel(link))


  for x in pool:
    let res = ^x
    echo "parallel: ", res.link, res.state

let res = decodeLink("https://dummyjson.com/products/1")
let p = decodeLinkParallel("https://dummyjson.com/products/1")

echo p.link, " ", p.state
echo res.link, " ", res.state

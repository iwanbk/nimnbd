import reactor/tcp, reactor/async
import collections/bytes
import negotiate

type
  NbdRequest = ref object
    magic*: uint32
    flags*: uint16
    cmdType*: uint16
    handle*: uint64
    offset*: uint64
    length*: uint32

  NbdClientFlags = object
    flags*: uint32

proc main(port: int, host = "127.0.0.1") {.async} =
  let srv = await createTcpServer(port, host)
  asyncFor client in srv.incomingConnections:
    await client.negotiate()
    let recvData = await client.input.read(sizeof(NbdRequest))
    echo("recv =", recvData)

main(6666).runLoop()

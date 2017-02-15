import reactor/tcp, reactor/async
import collections/bytes
import constants

type
  NbdNewStyleHeader* = object
    magic*: uint64
    optsMagic*: uint64
    globalFlags*: uint16

  NbdClientFlags = object
    flags*: uint32
   
  NbdClientOpt = object
    magic*: uint64
    id*:    uint32
    length*:   uint32

proc initNbdNewStyleHeader(): NbdNewStyleHeader =
  NbdNewStyleHeader(
    magic: NBD_MAGIC.uint64,
    optsMagic: NBD_OPTS_MAGIC.uint64,
    globalFlags:NBD_FLAG_FIXED_NEWSTYLE.uint16
    )

proc toBin(nsh: NbdNewStyleHeader): string =
  result = newStringOfCap(18)
  result &= pack(nsh.magic, bigEndian)
  result &= pack(nsh.optsMagic, bigEndian)
  result &= pack(nsh.globalFlags, bigEndian)

proc unpackClientOpt(s: string): NbdClientOpt =
  result = NbdClientOpt()
  result.magic = unpack(s[0..8], uint64, bigEndian)
  result.id = unpack(s[8..12], uint32, bigEndian)
  result.length = unpack(s[12..16], uint32, bigEndian)

proc negotiate*(conn: TcpConnection) {.async} =
  let nsh = initNbdNewStyleHeader()
  await conn.output.write(nsh.toBin)

  discard await conn.input.read(sizeof(NbdClientFlags))

  var done = false
  while not done:
    let inp = await conn.input.read(sizeof(NbdClientOpt))
    echo("inp=",inp)
    let opt = unpackClientOpt(inp)
    if opt.magic != NBD_OPTS_MAGIC.uint64:
      echo("bad option magic")
    echo("ok")

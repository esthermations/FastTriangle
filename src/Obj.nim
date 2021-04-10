import aglet, strutils, sequtils

type
  ObjData = object
    pos*: seq[Vec3f]
    nor*: seq[Vec3f]
    txc*: seq[Vec3f]

  ObjVertex = tuple[pos, nor, txc: Vec3f]

func isValid*(obj: ObjData): bool =
  return
    (obj.pos.len == obj.nor.len) and
    (obj.txc.len == obj.pos.len or obj.txc.len == 0)

func numVertices*(obj: ObjData): int =
  assert obj.isValid()
  obj.pos.len

func hasTexCoords*(obj: ObjData): bool =
  obj.txc.len != 0

iterator pairs*(obj: ObjData): (int, ObjVertex) =
  assert obj.isValid()
  for i in 0 ..< obj.numVertices():
    yield (i, (
      pos: obj.pos[i],
      nor: obj.nor[i],
      txc: (if obj.hasTexCoords(): obj.txc[i] else: vec3f(0.0))
    ))

iterator items*(obj: ObjData): ObjVertex =
  for (i, v) in obj.pairs():
    yield v

### Convert a sequence of strings, each containing one float, to a vector.
func toVec[N : static[int]](strs: seq[string], fillWithZeroes: bool = false): Vec[N, float32] =
  assert fillWithZeroes or (strs.len == N)
  assert result.arr.allIt(it == 0.0)
  for i in 0 ..< strs.len:
    result.arr[i] = parseFloat(strs[i])

type ObjIndices = tuple[pos, nor, txc: int]
const objIndexNotSet = -1

func faceToIndices(restOfLine: seq[string]): seq[ObjIndices] =
  for face in restOfLine:
    let indices = face.split("/").mapIt(it.parseInt()).mapIt(it - 1)
    assert indices.len in [2, 3]
    assert indices.allIt(it >= 0)

    let
      haveTexCoords = (indices.len == 3)
      posIndex = indices[0]
      norIndex = (if haveTexCoords: indices[2] else: indices[1])
      txcIndex = (if haveTexCoords: indices[1] else: objIndexNotSet)

    result.add (posIndex, norIndex, txcIndex)

func parseObj*(fileContents: string): ObjData =
  var
    uniquePos: seq[Vec3f]
    uniqueNor: seq[Vec3f]
    uniqueTxc: seq[Vec3f]

  for line in fileContents.splitLines():
    let splitLine = line.splitWhitespace()
    if splitLine.len == 0 or splitLine[0].startsWith("#"):
      continue

    let
      token = splitLine[0]
      restOfLine = splitLine[1 ..< splitLine.len]

    case token
    of "v" : uniquePos.add toVec[3](restOfLine)
    of "vn": uniqueNor.add toVec[3](restOfLine)
    of "vt": uniqueTxc.add toVec[3](restOfLine, fillWithZeroes = true)
    of "f" :
      let
        indices = faceToIndices(restOfLine)
        numVerticesInFace = restOfLine.len

      assert numVerticesInFace in [3, 4], "We only support quads or triangles."

      template addVertex(triangle: ObjIndices): untyped =
        assert triangle.pos < uniquePos.len
        result.pos.add uniquePos[triangle.pos]
        assert triangle.nor < uniqueNor.len
        result.nor.add uniqueNor[triangle.nor]
        if triangle.txc != objIndexNotSet:
          assert triangle.txc < uniqueTxc.len
          result.txc.add uniqueTxc[triangle.txc]

      template addVertices(triangles: openArray[ObjIndices]): untyped =
        for t in triangles:
          addVertex t

      case numVerticesInFace
      of 3:
        # Triangle
        addVertices indices
      of 4:
        # Quad
        let (a, b, c, d) = (indices[0], indices[1], indices[2], indices[3])
        addVertices [a, b, c]
        addVertices [c, d, a]
      else:
        # This should be caught by the assert in faceToIndices.
        assert false
    else:
      continue

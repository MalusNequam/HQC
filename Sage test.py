import numpy as np
import komm
import sys
import json

RM = komm.ReedMullerCode(1,8)
decoder = komm.ReedDecoder(RM)

w = json.loads(sys.argv[1])

w = np.array(w, dtype=int)

m = decoder.decode(w)

print(list(map(int,m)))

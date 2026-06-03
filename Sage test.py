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
# # Deine 5x3 Matrix definieren
# A = matrix(QQ, 5, 3, [
#     [2, 4, 2],
#     [1, 3, 3],
#     [0, 1, 4],
#     [1, 2, 1],
#     [3, 7, 5]
# ])

# # Berechnet die reduzierte Form und die Transformationen gleichzeitig
# E = A.extended_echelon_form()

# # Sage teilt das Ergebnis in zwei Bereiche:
# # Die ersten 3 Spalten (0 bis 3) sind die rref-Matrix B
# # Die restlichen 5 Spalten (3 bis 8) sind die Transformationsmatrix T

# B = E.submatrix(0, 0, 5, 3)
# T = E.submatrix(0, 3, 5, 5)

# print("Transformationsmatrix T (5x5):")
# print(T)
# print("\nErgebnis B (5x3):")
# print(B)

# # Überprüfung: T * A muss gleich B sein
# assert T * A == B

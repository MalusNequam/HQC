import numpy as np 
from sage import *
from Crypto.Hash import SHAKE256, SHA3_256, SHA3_512
import random
from sage.crypto.util import ascii_to_bin
from sage.crypto.util import bin_to_ascii
import math
import komm
import subprocess
import json
# XOF_DOMAIN_SEPARATOR = b'\x00'
# G_DOMAIN_SEPARATOR   = b'\x01'
# H_DOMAIN_SEPARATOR   = b'\x02'
# I_DOMAIN_SEPARATOR   = b'\x03'
# J_DOMAIN_SEPARATOR   = b'\x04'"
class HQC:


    def __init__(self, n, R_w, R_e, R_r, r, m, k_RM, delta, l):
        self.n = n
        self.l = l
        self.r = r
        self.m = m
        self.n_size = (n + 7) // 8
        self.R_w = R_w
        self.R_e = R_e
        self.R_r = R_r
        self.delta = delta
        self.seed_size = 32
        self.F = GF(2)
        self.R = PolynomialRing(self.F, 'x')
        self.x = self.R.gen()
        self.k_RM = k_RM
        self.u_length = 0
        self.v_length = 0
        self.len_M = 0


        self.S = self.R.quotient(self.x**self.n + 1, "xbar")
        self.xbar = self.S.gen()
        self.RM2 = komm.ReedMullerCode(int(self.r), int(self.m))
        self.decoder = komm.ReedDecoder(self.RM2, input_type = "hard")

    def XOF_init(self, seed = b" "):
        xof = SHAKE256.new(seed + b"\x01")
        return xof
    def XOF_get_bytes(self, xof, size):
        b = xof.read(size)
        if size % 8 != 0:
            xof.read(8- size % 8)
        return b
    def I(self, seed):
        Domain_Seperator_I = b'\x03'
        i = SHA3_512.new()
        i.update(seed + Domain_Seperator_I)
        h = i.digest()
        s_pke_dk = h[:32]
        s_pke_ek = h[32:]
        return s_pke_dk, s_pke_ek

    def SampleFixedWeightVect(self, ctx, R):
        vec = [0] * self.n
        random.seed(ctx)
        count = 0
        while count < R:
            j = random.randint(0,self.n-1)
            if vec[j] == 0:
                vec[j] = 1
                count += 1

        return self.S(vec)

    def sample_vect(self, ctx):
        random.seed(ctx)
        t = random.randint(0,self.n-1)
        vec = [0] * t + [1]*(self.n - t)

        random.shuffle(vec)

        return self.S(vec)

    def Truncate(self, poly, lenght):
        coeffs = poly.list()
        coeffs = coeffs[:self.l]
        coeffs += [0] * (self.l - len(coeffs))
        return self.R(coeffs)


    def Keygen(self, seed_pke):
        seed_dk, seed_ek = self.I(seed_pke)
        bytes_seed_dk = bytes(seed_dk)

        # compute decryption key
        y = self.SampleFixedWeightVect(bytes_seed_dk + b"y", self.R_w)
        x = self.SampleFixedWeightVect(bytes_seed_dk + b"x", self.R_w)

        # compute encryption key
        bytes_seed_ek = bytes(seed_ek)
        h = self.sample_vect(bytes_seed_ek + b"h")
        s = x + h * y
       

        pk = (h, s)
        sk = (x, y)
        return (pk, sk)



    def Encryption(self, M, pk, seed):
        encoder = komm.BlockCode(generator_matrix = self.RM2.generator_matrix)
        U = []
        V = []
        h = self.S(pk[0].list())
        s = self.S(pk[1].list())
        seed_dk, seed_ek = self.I(seed)
        bytes_seed_dk = bytes(seed_dk)
        # Transforming M into a ASCII string
        M_ASCII7 = "".join(format(ord(c), '07b') for c in M)
        self.len_M = len(M_ASCII7)
        t = math.ceil(len(M_ASCII7)/self.k_RM)
        M_tilde = M_ASCII7 + "0"*(t * self.k_RM - len(M_ASCII7))
 

        M_blocks = [M_tilde[i : i + self.k_RM] for i in range(0, len(M_tilde), self.k_RM)]

        M_vecs = [
        vector(GF(2), [int(b) for b in M_blocks[i]])
        for i in range(t)
]
        for i in range(t):
            zahl = i
            daten = zahl.to_bytes(1, byteorder = "big")
            c_RM = encoder.encode(M_vecs[i])
            poly_c_RM = self.R(c_RM.tolist())

            r_1 = self.SampleFixedWeightVect(bytes_seed_dk + b"r1" + daten, self.R_r)
            r_2 = self.SampleFixedWeightVect(bytes_seed_dk + b"r2" + daten, self.R_r)
            e = self.SampleFixedWeightVect(bytes_seed_dk + b"e" + daten, self.R_e)

            u = r_1 + h * r_2
            v = poly_c_RM + (self.Truncate(s * r_2 + e, self.l))
            U.append(u)
            V.append(v)

        return (U, V)


    def decryption(self, sk, out_enc):

        U, V = out_enc
        s, y = sk
        t = len(U)
        M_bits_total = ""

        for i in range(t):

            w = V[i] - self.Truncate(U[i] * y, self.l)
            w_list = [int(x) for x in w.list()]

            w_list += [0] * (self.l - len(w_list))
            w_list_python = [int(x) for x in w_list] 

            result = subprocess.check_output([
                "python", 
                "Sage test.py", 
                json.dumps(w_list_python)
            ])

            m_block = result.decode().strip()

            m_block = m_block.replace("[", "").replace("]", "").replace(",", "").replace(" ", "")
            M_bits_total += m_block

        M_clean = M_bits_total


        M_neu = "".join(chr(int(M_clean[i:i+7], 2)) for i in range(0, len(M_clean), 7))

        print(f"Originale Bits: {M_clean}")
        print(f"Nachricht: {M_neu}")

        return M_neu



# def __init__(self, n, R_w, R_e, R_r, r, m, k_RM, delta, l):
A = HQC(n = 269, R_w = 6, R_e = 7, R_r = 7, r = 1, m = 8, k_RM = 9, delta = 0, l = 256)
seed = b"123"
ctx_1, ctx_2 = A.I(seed)
ctx_2 = A.XOF_init(ctx_2)
ctx_2 = A.XOF_get_bytes(ctx_2, 5)

pk, sk = A.Keygen(seed)

U, V = A.Encryption("Klopf, Klopf! Wer da? Bremen!", pk, seed)

U_list = []
V_list = []
h, s = pk
x, y = sk


A.decryption(sk, (U, V))

# for u in U:
#     U_list.append(u.list() + [0]*(269 - len(u.list())))
# # print(U_list)

# for v in V:
#     V_list.append(v.list() + [0]*(256 - len(v.list())))
# # print(V_list)

# print(x.list())
# print()
# print(y.list())










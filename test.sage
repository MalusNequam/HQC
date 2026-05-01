import numpy as np 
from sage import *
from Crypto.Hash import SHAKE256, SHA3_256, SHA3_512
import random

# XOF_DOMAIN_SEPARATOR = b'\x00'
# G_DOMAIN_SEPARATOR   = b'\x01'
# H_DOMAIN_SEPARATOR   = b'\x02'
# I_DOMAIN_SEPARATOR   = b'\x03'
# J_DOMAIN_SEPARATOR   = b'\x04'"
class HQC:


    def __init__(self, n1, n2, n, lev, R_w, R_e, R_r, delta):
        self.lev = lev
        self.n = n
        self.n1 = n1
        self.n2 = n2
        self.n_size = (n + 7) // 8
        self.lev = lev
        self.R_w = R_w
        self.R_e = R_e
        self.R_r = R_r
        self.delta = delta
        self.n1n2 = n1 * n2
        self.seed_size = 32
        self.F = GF(2)
        self.R = PolynomialRing(self.F, 'x')
        self.x = self.R.gen()
        self.u_length = 0
        self.v_length = 0


        self.S = self.R.quotient(self.x**self.n + 1, "xbar")
        self.xbar = self.S.gen()

    def poly_to_bytes(self, poly):
        poly_obj = poly.lift()
        out = bytearray(self.n_size)
        for exp, coeff in poly_obj.dict().items():
            # Falls das Polynom Lücken hat oder der Grad unerwartet hoch ist
            if exp < self.n:
                # Koeffizient modulo 2 (für binäre Darstellung)
                if int(coeff) % 2 == 1:
                    out[exp // 8] |= (1 << (exp % 8))
        return bytes(out)

    def bytes_to_poly(self, data):
        p = self.S(0)

        for i in range(self.n):
            byte = data[i // 8]
            bit = (byte >> (i % 8)) & 1
            if bit:
                p += self.xbar**i

        return p

    def XOF_init(self, seed = b" "):
        xof = SHAKE256.new(seed + b"01")
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


    def SampleFixedWeightVect(self, xof, weight):
        pos = [0] * weight

        def rand(n, xof):
            x = int.from_bytes(self.XOF_get_bytes(xof, 4), "little")
            return x % n

        for i in range(weight - 1, -1, -1):

            l = i + rand(weight, xof)
            dub = False
            for j in range(i + 1, weight):
                if pos[j] == l:
                    dub = True
                    break
            if dub:
                pos[i] = i
            else:
                pos[i] = l
        v = self.S(0)
        for p in pos:
            v += self.xbar**p
        return xof, v

    def sample_vect(self, ctx):
        v = self.XOF_get_bytes(ctx, self.n_size)
        v = int.from_bytes(v, byteorder="little")
        v &= (1<< self.n) - 1
        p = self.S(0)
        i = 0
        while v:
            if v & 1:
                p += self.xbar**i
            v >>= 1
            i += 1
        return ctx, p

    def Keygen(self, seed_pke):
        seed_dk, seed_ek = self.I(seed_pke)

        # compute decryption key
        ctx_dk = self.XOF_init(seed_dk)
        ctx_dk, y = self.SampleFixedWeightVect(ctx_dk, self.R_w)
        ctx_dk, x = self.SampleFixedWeightVect(ctx_dk, self.R_w)
        dk_pke = seed_dk

        # compute encryption key
        ctx_ek = self.XOF_init(seed_ek)
        ctx_ek, h = self.sample_vect(ctx_ek)
        s = x + h * y
        print(seed_ek)
        print()
        print(s)
        print()
        s = self.poly_to_bytes(s)
        ek_pke = seed_ek + s

        return ek_pke, dk_pke

    def Key_Encryption(self, seed, m, theta):
        seed_ek = seed[0: len(seed) - self.n_size]
        ctx_ek = self.XOF_init(seed_ek)
        ctx_ek, h = self.sample_vect(ctx_ek)
        s = seed[len(seed)-self.n_size: len(seed)]
        print()
        print(seed_ek)
        print()
        print(self.bytes_to_poly(s))
        print()

        # compute ciphertext
        ctx_theta = self.XOF_init(theta)
        ctx_theta, r_2 = self.SampleFixedWeightVect(ctx_theta, self.R_r)
        ctx_theta, e = self.SampleFixedWeightVect(ctx_theta, self.R_e)
        ctx_theta, r_1 = self.SampleFixedWeightVect(ctx_theta, self.R_r)
        u = r_1 + e * r_2

        v = r_1 + e

        u = self.poly_to_bytes(u)
        v = self.poly_to_bytes(v)
        self.u_length = len(u)
        self.v_length = len(v)

        c_pke = (u + v)
        return c_pke

    def Key_decryption(self,dk_pke, c_pke):

        # Parse decryption key
        seed_pke = dk_pke[0:len(dk_pke)- self.n_size]
        ctx_pke = self.XOF_init(seed_pke)
        ctx_pke, y = self.SampleFixedWeightVect(ctx_pke, self.R_w)

        # Parse ciphertext
        u = c_pke[0:self.u_length]
        v = c_pke[self.u_length: len(c_pke)]


        # create plaintext m
        print(self.bytes_to_poly(u))
        print(self.bytes_to_poly(v))
        return u










A = HQC(n=16, n1=1, n2=1, lev=1, R_w=5, R_e=3, R_r=2, delta=2)

seed = b"123546"
m = "HAllO"
theta = b"432"

ek, dk = A.Keygen(seed)

# Übergib nur ek an die Encryption
t2 = A.Key_Encryption(ek, m, theta)
print(t2)
t3 = A.Key_decryption(dk, t2)

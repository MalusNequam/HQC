import numpy as np 
from sage import *
from Crypto.Hash import SHAKE256, SHA3_256, SHA3_512
import random
from sage.crypto.util import ascii_to_bin
from sage.crypto.util import bin_to_ascii
import math
#import komm
# XOF_DOMAIN_SEPARATOR = b'\x00'
# G_DOMAIN_SEPARATOR   = b'\x01'
# H_DOMAIN_SEPARATOR   = b'\x02'
# I_DOMAIN_SEPARATOR   = b'\x03'
# J_DOMAIN_SEPARATOR   = b'\x04'"
class HQC:


    def __init__(self, n, R_w, R_e, R_r, r, m, delta, l):
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
        self.RM = codes.ReedMullerCode (order = self.r, num_of_var = self.m, base_field = self.F)
        self.k_RM = self.RM.dimension()
        self.u_length = 0
        self.v_length = 0


        self.S = self.R.quotient(self.x**self.n + 1, "xbar")
        self.xbar = self.S.gen()

        #self.RM2 = komm.ReedMullerCode(self.r, self.m)
        #self.decoder = komm.ReedDecoder(self.RM2, input_typ = "hard")

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

    def SampleFixedWeightVect(self,ctx,R):
        vec = [0]*self.n
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
        print(vec)
        random.shuffle(vec)
        print(vec)
        return self.S(vec)


A = HQC(8,2,2,2,2,2,2,2)
ctx_1, ctx_2 = A.I(b"112243554632433435344")
ctx_2 = A.XOF_init(ctx_2)
ctx_2 = A.XOF_get_bytes(ctx_2, 5)

y = A.SampleFixedWeightVect(ctx_2 + b"y",2)
x = A.SampleFixedWeightVect(ctx_2 + b"x",2)
print(A.sample_vect(ctx_2))


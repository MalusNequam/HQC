import numpy as np 
from sage import *
from Crypto.Hash import SHAKE256, SHA3_256, SHA3_512
import random
from sage.crypto.util import ascii_to_bin
from sage.crypto.util import bin_to_ascii
import math
import komm
# XOF_DOMAIN_SEPARATOR = b'\x00'
# G_DOMAIN_SEPARATOR   = b'\x01'
# H_DOMAIN_SEPARATOR   = b'\x02'
# I_DOMAIN_SEPARATOR   = b'\x03'
# J_DOMAIN_SEPARATOR   = b'\x04'"
class HQC:


    def __init__(self, n1, n2, n, R_w, R_e, R_r, r, m, delta, l):
        self.n = n
        self.l = l
        self.r = r
        self.m = m
        self.n1 = n1
        self.n2 = n2
        self.n_size = (n + 7) // 8
        self.R_w = R_w
        self.R_e = R_e
        self.R_r = R_r
        self.delta = delta
        self.n1n2 = n1 * n2
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

        self.RM2 = komm.ReedMullerCode(self.r, self.m)
        self.decoder = komm.ReedDecoder(self.RM2, input_typ = "hard")
        # 
        #
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

    def bytes_to_poly(self, data, is_k_RM=False):
        p = self.R(0) if is_k_RM else self.S(0)
        

        bit_index = 0
        for byte in data:
            for i in range(8):
                if (byte >> i) & 1:
                    if is_k_RM:
                        p += self.x**bit_index
                    else:
                        p += self.xbar**bit_index
                bit_index += 1
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
    
    def Truncate(self, poly):
        coeffs = poly.list()
        coeffs = coeffs[:self.l]
        coeffs += [0] * (self.l - len(coeffs))
        return vector(GF(2), coeffs)

        


    def SampleFixedWeightVect(self, xof, weight):
        def rand_below(n, xof):
            # 32 Bit aus XOF lesen
            x = int.from_bytes(self.XOF_get_bytes(xof, 4), "little")
            return x % n

        # Eindeutige Positionen sammeln
        positions = set()

        while len(positions) < weight:
            p = rand_below(self.n, xof)
            positions.add(p)

        # Polynom erzeugen
        v = self.S(0)

        for p in positions:
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
        # print(seed_ek)
        # print()
        # print(s)
        # print()
        s = self.poly_to_bytes(s)
        ek_pke = seed_ek + s

        return ek_pke, dk_pke

    def Key_Encryption(self, seed, M, theta):
        U = []
        V = []

        seed_ek = seed
        ctx_ek = self.XOF_init(seed_ek)
        ctx_ek, h = self.sample_vect(ctx_ek)
        s = seed[len(seed)-self.n_size: len(seed)]
        s = self.bytes_to_poly(s)
        ctx_theta = self.XOF_init(theta)
        
        # For encryption
        M_ASCII7 = "".join(format(ord(c), '07b') for c in M)
        t = math.ceil(len(M_ASCII7)/self.k_RM)
        added_zeros = t * self.k_RM - len(M_ASCII7)
        M_tilde = M_ASCII7 + "0" * added_zeros



        M_blocks = [M_tilde[i : i + self.k_RM] for i in range(0, len(M_tilde), self.k_RM)]
        encoded_blocks = []
        C_RM = []
        for block in M_blocks:
            m_vec = vector(GF(2), [int(b) for b in block])
            # 2. Reed-Muller Kodierung (Ergebnis Länge n2 = 256)
            c_i = self.RM.encode(m_vec)
            encoded_blocks.append(vector(self.F, c_i))
            C_RM.append(self.R(c_i.list()))
        #print(encoded_blocks)
        for i in range(t):

            ctx_theta, r_2 = self.SampleFixedWeightVect(ctx_theta, 0)
            ctx_theta, e = self.SampleFixedWeightVect(ctx_theta, 0)
            ctx_theta, r_1 = self.SampleFixedWeightVect(ctx_theta, self.R_r)

            u = r_1 + h * r_2
            c_list = C_RM[i].list()
            c_list += [0] * (self.l - len(c_list))

            v = encoded_blocks[i] + self.Truncate(s * r_2 + e)
            # print(len(u.list()))
            # print(len(v.list()))
            U.append(u)
            V.append(v)

        c = [U, V]


        return c

    def Key_decryption(self, dk_pke, c_pke):

        # Parse decryption key
        seed_pke = dk_pke[0:len(dk_pke)- self.n_size]
        ctx_pke = self.XOF_init(seed_pke)
        ctx_pke, y = self.SampleFixedWeightVect(ctx_pke, self.R_w)

        U = c_pke[0]
        V = c_pke[1]

        t = len(U)
        M_bits_total = ""
        
        for i in range(t):
            # 1. Rauschen entfernen
            w_poly = V[i] - self.Truncate(U[i] * y)
            
            # 2. In Vektor umwandeln (muss exakt n2 lang sein!)
            w_list = w_poly.list()
            print(len(w_list))
            w_list = w_list[:self.l] + [0] * (self.l - len(w_list[:self.l]))
            print(len(w_list))
            w_vec = V[i] + self.Truncate(U[i] * y)
            
            # 3. KORREKTER DECODER AUFRUF
            print(type(w_vec))
            print(len(w_vec))
            print(w_vec.parent())
            m_vor_vec = self.RM.decode_to_message(w_vec)
            print(i)
            
            # Bits sammeln
            M_bits_total += "".join(map(str, m_vor_vec))
            

        while len(M_bits_total) % 7 != 0:
            M_bits_total = M_bits_total[:-1]

        chars = []
        for i in range(0, len(M_bits_total), 7):
            chunk = M_bits_total[i:i+7]
            chars.append(chr(int(chunk, 2)))

        return "".join(chars)










A = HQC(n=269, n1=1, n2=1, R_w=6, R_e=7, R_r=7, delta=2, m = 8, r = 1, l = 256)

seed = b"1234556546"
m = "HAllO"
theta = b"432"

ek, dk = A.Keygen(seed)

# Übergib nur ek an die Encryption
t2 = A.Key_Encryption(ek, m, theta)
#print(t2)
t3 = A.Key_decryption(dk, t2)





# RM = codes.ReedMullerCode(order = 1, num_of_var = 3, base_field = GF(2))


# k_RM = RM.dimension() # Das ist 9

# # Wort in 7-Bit ASCII umwandeln
# m_bits = "".join(format(ord(c), '07b') for c in "Hallo")

# # Padding auf Vielfaches von k_RM (9)
# t = math.ceil(len(m_bits) / k_RM)
# m_tilde = m_bits.ljust(t * k_RM, '0')

# In Blöcke der Länge 9 teilen
# M_blocks = [m_tilde[i : i + k_RM] for i in range(0, len(m_tilde), k_RM)]
# encoded_blocks = []
# for block in M_blocks:
#     # 1. String in Vektor umwandeln
#     m_vec = vector(GF(2), [int(b) for b in block])
    
#     # 2. Reed-Muller Kodierung (Ergebnis Länge n2 = 256)
#     c_i = RM.encode(m_vec)
#     encoded_blocks.append(c_i)
# print(encoded_blocks)


# 1. Setup: Kleiner RM-Code zum Testen
# r=1, m=3 -> Länge n2 = 2^3 = 8, Dimension k_RM = 4
# r_test = 1
# m_test = 3
# RM_test = codes.ReedMullerCode(num_of_var = m_test, order = r_test, base_field = GF(2))

# print(f"Code Länge (n2): {RM_test.length()}")
# print(f"Nachrichten-Bits (k_RM): {RM_test.dimension()}")

# # 2. ENCODE: Eine Test-Nachricht (Länge 4)
# m_original = vector(GF(2), [1, 0, 1, 1])
# c_word = RM_test.encode(m_original)
# print(f"Codiertes Wort: {c_word}")

# # 3. FEHLER EINBAUEN: Wir kippen ein Bit (Simulation von Rauschen)
# c_noisy = copy(c_word)
# c_noisy[0] = c_noisy[0] + 1  # Das erste Bit umdrehen
# print(f"Wort mit Fehler: {c_noisy}")

# # 4. DECODE: Zurück zur Nachricht
# # Wir nutzen den 'BDD' Decoder, der bei RM stabil läuft
# try:
#     # Schritt A: Decoder-Instanz erstellen
    
#     # Schritt B: Dekodieren
#     m_decoded =RM_test.decode_to_message(c_noisy)
    
#     print(f"Dekodierte Nachricht: {m_decoded}")
#     print(f"Erfolg? {m_original == m_decoded}")

# except Exception as e:
#     print(f"Fehler beim Dekodieren: {e}")
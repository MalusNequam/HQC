import numpy as np
from sympy import Matrix
from scipy.linalg import circulant
import time
n = 269
w = 6
w_e = 7 
w_r = 7 
r = 1
m = 8
l = 256

n_prime = int(2*n)
k = int(n)
n_prime_test = int(2*n)
k_test = int(n)
pk = ([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1])
print(np.array(pk[0],dtype = int).sum())

s_test = np.array(pk[1],dtype = int)
y_test = np.array([0,0,1,1],dtype= int)
x_test = np.array([0,1,1,0],dtype = int)
h = np.array( pk[0]  , dtype = int)
H = circulant(h)
# print(H)
I_n = np.eye(n)
P = np.concatenate((I_n, H), axis=1)

def rank_f2(A):
    A = A.copy() % 2
    n, m = A.shape
    r = 0

    for c in range(m):
        pivot = None

        for i in range(r, n):
            if A[i, c] == 1:
                pivot = i
                break

        if pivot is None:
            continue

        A[[r, pivot]] = A[[pivot, r]]

        for i in range(n):
            if i != r and A[i, c] == 1:
                A[i] ^= A[r]

        r += 1

    return r


def is_invertible_f2(A):
    A = np.array(A, dtype=np.uint8) % 2
    n, m = A.shape
    if n != m:
        return False
    return rank_f2(A) == n

def inv_gf2(A):

    A = np.array(A, dtype=np.uint8) % 2

    n = A.shape[0]

    I = np.eye(n, dtype=np.uint8)

    AI = np.hstack((A, I)).astype(np.uint8)

    for col in range(n):

        pivot = None

        for row in range(col, n):

            if AI[row, col] == 1:
                pivot = row
                break

        if pivot is None:
            raise ValueError("nicht invertierbar")

        # Zeilen tauschen
        AI[[col, pivot]] = AI[[pivot, col]]

        # XOR-Elimination
        for row in range(n):

            if row != col and AI[row, col] == 1:

                AI[row] ^= AI[col]

    return AI[:, n:] % 2


def find_sk(P, s, w_e = int(2)):
    det = 0
    w_test = 0

    while w_test != w_e:
        while det == 0:
            H = np.eye(n_prime_test)[np.random.permutation(n_prime_test)]
            P_check = (P @ H) % 2
            #print(P_check)
            #print()
            P1 = P_check[0:k_test, 0:k_test]
            # print(P1)
            # print()
            if is_invertible_f2(P1):
                det = 1 
        s_t = (inv_gf2(P1) @ s) % 2

        det = 0
        null = np.zeros(k_test)
        s_vec = np.concatenate((s_t,null))
        if s_t.sum() <= 50:
            print(s_t.sum())
        if s_t.sum() == w_e: 
            # print((H @ s_vec)[0:k_test])
            print((H @ s_vec)[0:k_test].sum())
            if (H @ s_vec)[0:k_test].sum() !=w_e / 2:
                w_test = 0
            else:
                w_test = w_e
        

    s_vec = np.concatenate((s_t,null))
    null = np.zeros(k_test)
    s_vec = np.concatenate((s_t,null))
    return H @ s_vec
        
x_found = find_sk(P, s_test, int(12))[0:n]
print(x_found)
x_found = np.array(x_found, dtype = int)
print(x_found)
x_list = list(x_found)

#  [0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 1. 0. 0. 0. 0. 1. 0. 0. 1. 0. 0. 0. 0. 0. 0. 0.]
#   [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]  


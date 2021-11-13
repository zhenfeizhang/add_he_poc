import time

# ===========================================
# parameters

# modulus for R
q = 2^69+1

# dimension of irreducible polynomial
n = 1024


# BLS group order
p = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001

# set q % 2n == 1 so that q is NTT-friendly (not matter for this POC though)
while q.is_prime() == false:
    q = q + 2*n

# polynomial ring
PQ.<x> = PolynomialRing(Zmod(q))
PZ.<x> = PolynomialRing(ZZ)
F = PZ(x^n + 1)

beta_e = 1
beta_e_1 = 1
beta_e_2 = 1
beta_s = 2^23
beta_r = 2^23

# 2 \times 256 \times the unpper bound of "additions"
modulus_r = 2^23

# ===========================================
# functions

# sample a uniformly random element in R
def sample_r():
    return [ZZ.random_element(0, q) for _ in range (n)]

# sample a random element whose coefficient is bounded by beta
def sample_bounded(beta):
    return [ZZ.random_element(-beta, beta+1) for _ in range (n)]


# key generation
def key_gen():
    a = sample_r()
    s = sample_bounded(beta_s)
    e = sample_bounded(beta_e)
    b = (PZ(a) * PZ(s) + modulus_r * PZ(e))%F%q
    return ((a, b.list()), (s, e))


# encrypting a message integer between [0, p)
# a bit string of dimention 256
def encrypt(pk, message):
    (a, b) = pk
    m_str = message.bits()
    m = PZ(m_str)

    r = sample_bounded(beta_r)
    e1 = sample_bounded(beta_e_1)
    e2 = sample_bounded(beta_e_2)

    c1 = (PZ(a) * PZ(r) + modulus_r * PZ(e1))%F%q
    c2 = (PZ(b) * PZ(r) + modulus_r * PZ(e2) + m)%F

    return (c1.list(), c2.list())

# decrypt a message and lift it to an integer between [0, p)
def decrypt(sk, cipher):
    (c1, c2) = cipher
    (s, e) = sk
    mx = PZ(PZ(c2) - PZ(c1) * PZ(s) % F)%q

    # center lift m to the range [-q/2, q/2)
    m_list = mx.list()
    m_lifted = []
    for e in m_list:
        if e > q/2:
            m_lifted.append(e - q)
        else:
            m_lifted.append(e)

    m = PZ(m_lifted) % modulus_r
    print(m)
    return m(2)


# ===========================================
# tests

# correctness of encryption
for _ in range(100):
    (pk, sk) = key_gen()
    message = ZZ.random_element(1, p)
    cipher = encrypt(pk, message)

    message_rec = decrypt(sk, cipher)
    assert(message == message_rec)


#
# # ===========================================
# # proof of custody
# (pk, sk) = key_gen()
# k = Zmod(p).random_element()
# k_list = []
# d_list = []
# cipher_list = []
# sum = 0
# for i in range(2^4):
#     k_i = k^i
#     k_list.append(ZZ(k_i))
#     di = Zmod(5).random_element()
#     d_list.append(ZZ(di))
#     (c1, c2) = encrypt(pk, message)
#     for _ in range(len(c1), n):
#         c1.append(0)
#     for _ in range(len(c2), n):
#         c2.append(0)
#     cipher_list.append((vector(c1), vector(c2)))
#     sum += ZZ(k_i)
#
# t1 = time.process_time()
#
# res0 = d_list[0] * vector(cipher_list[0][0])
# res1 = d_list[0] * vector(cipher_list[0][1])
#
# for i in range(1, 2^4):
#     res0 += d_list[i] * vector(cipher_list[i][0])
#     res1 += d_list[i] * vector(cipher_list[i][1])
#
# t1 = time.process_time() - t1
# print("total time for homomorphic additions:", t1)
#
# # check the correctness after additions
# m =  decrypt(sk, (res0.list(), res1.list()))
# print(m, sum)

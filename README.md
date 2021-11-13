# Additive homomorphic encryption for proof of custidy

## Notations

Let $\mathcal{R} := \mathbb{Z}_q[x]/(x^n+1)$ be a polynomial ring with parameters $q$ and $n$.
Denote by $\times$ the ring multiplications, and $\cdot$ integer multiplications.
Let $\mathbb{F}_p$ be a finite field of order $p$.
For a polynomial ${\bf f}(x) := \sum_{i=0}^{n-1} f_i x^i$, denote by ${\bf f} := (f_0,\dots, f_{n-1})$ the vector form of ${\bf f}(x)$. We abuse the notation between ${\bf f}(x)$ and ${\bf f}$ when there is no ambiguity.

## Tentitive Parameters
The following parameters gives a 128 bit security under the quantum-core-BKZ model, achieving a BKZ constant of $1.003$. The ciphertext with the following parameters will be roughly __17 KB__ each.

- $n = 1024$; degree of the polynomials
- $q > 2^{67}$; modulus, an NTT-friendly prime for $\mathcal{R}$ 
- $p = \texttt{0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001}$; BLS group order
- $r = 2^{22}$; modulus, the HE is homomorphic over $\mathbb{F}_r^n$
- $k = 2^{13}$: number of ciphertextst that will be added together ($n$ in Dankrad's note) 
- $\beta_s = 2^{22}$: inifinity norm bound, the secret in public key will be sampled with coefficients between $-\beta_s$ and $\beta_s$
- $\beta_{e} = 1$: inifinity norm bound, the errors in public key will be sampled with coefficients between $-\beta_e$ and $\beta_e$
- $\beta_r = 2^{22}$: inifinity norm bound, the secret in encryption will be sampled with coefficients between $-\beta_r$ and $\beta_r$
- $\beta_{e_1} = 1$: inifinity norm bound, the fist error term in encryption will be sampled with coefficients between $-\beta_{e_1}$ and $\beta_{e_1}$
- $\beta_{e_2} = 1$: inifinity norm bound, the second error term in encryption will be sampled with coefficients between $-\beta_{e_2}$ and $\beta_{e_2}$

Note that we may optimize the ciphertext size via a better and detailed infinity norm bound analysis.
We may further save around 6 bits per coefficient, or 1.5 KB via embedding 4 coefficients in a single ring elements (the randomizer will need to be adjusted accordingly).
## Aux functions

The function $\texttt{Map_to_}\mathcal{R}: \mathbb{F}_p\mapsto \mathcal{R}$ takes the following steps

- ${\bf a} = fp\_elem.\texttt{to_le_bits()}$
- return $\sum_{i=0}^{n-1} a_i x^i$ 

Note: for the parameter we have chosen, we may embed 4 $\mathcal{F}$ elements in a signle ring element, which prictically will reduce $r$ by $2$ bits, and total size by $2n$ which is 256 bytes.

## Scheme
This is a simple adaption of the FV homomorphic encryption scheme (And shares lot's of same properties with NewHope.).

- Key generation
    - sample uniformly at random ${\bf a} \in \mathcal{R}$ 
    - sample ${\bf s} \in \mathcal{R}$ with $\|{\bf s}\|_\infty\leq \beta_s$
    - sample ${\bf e} \in \mathcal{R}$ with $\|{\bf e}_0\|_\infty\leq \beta_{e}$ 
    - compute ${\bf b} = {\bf a}  \times {\bf s} + r\cdot {\bf e}$
    - return $pk = ({\bf a}, {\bf b})$ and $sk =  ({\bf s}, {\bf e})$


- Encrypt an $\mathbb{F}_p$ element
    - for an input ${\bf a} \in \mathbb{F}_p$, compute ${\bf m} = \texttt{Map_to_}\mathcal{R}({\bf a})$
    - sample ${\bf r} \in \mathcal{R}$ with $\|{\bf r}\|_\infty\leq \beta_r$
    - sample ${\bf e}_1 \in \mathcal{R}$ with $\|{\bf e}_1\|_\infty\leq \beta_{e_1}$
    - sample ${\bf e}_2 \in \mathcal{R}$ with $\|{\bf e}_2\|_\infty\leq \beta_{e_2}$ 
    - compute ${\bf c}_1 =  {\bf a}  \times {\bf r} + r\cdot {\bf e}_1$ and  ${\bf c}_2 = {\bf b} \times {\bf r} + r\cdot {\bf e}_2 + {\bf m}$
    - output $cipher = ({\bf c}_1, {\bf c}_2)$

- Decrypt
    - compute ${\bf m}' = {\bf c}_2 - {\bf c}_1 \times {\bf s} \bmod 2^{r}$
    - return ${\bf m}'(2) = \sum_{i=0}^n m_i \cdot 2^i \in \mathbb{F}_p$


Decrypt is correct:
\begin{align}
    {\bf m}' &={\bf c}_2 - {\bf c}_1 \times {\bf s} \\
        &= {\bf a}\times{\bf s}\times{\bf r} + r  \cdot{\bf e}\times {\bf r} + r \cdot {\bf e}_2 + {\bf m} - {\bf a}\times{\bf s}\times{\bf r} - r  \cdot{\bf e}_1 \times {\bf s}  \\
        &\equiv {\bf m}  \bmod r
\end{align}
so long as each coefficient of $r \cdot {\bf e} \times{\bf r} + r  \cdot {\bf e}_2 + {\bf m} - r  \cdot {\bf e}_1  \times{\bf s}$ does not overflow $q$.


- Homomorphic additions
    - input two ciphtertexts $cipher_1 = ({\bf c}_{1}^{(1)}, {\bf c}_{2}^{(1)})$ and $cipher_2 = ({\bf c}_{1}^{(2)}, {\bf c}_{2}^{(2)})$, that encrypts ${\bf m}^{(1)}$ and ${\bf m}^{(2)}$, respectively
    - return  $({\bf c}_{1}^{(1)}+{\bf c}_{1}^{(2)}, {\bf c}_{2}^{(1)}+{\bf c}_{2}^{(2)})$


Addition is homomorphic, because, due to decryption equation, we will have ${\bf m}' \equiv {\bf m}^{(1)} + {\bf m}^{(2)} \bmod r$. So long as 

- each coeffcient of ${\bf m}^{(1)} + {\bf m}^{(2)}$ is less than $r$; and
- each coeffcient of $r \cdot {\bf e} \times({\bf r}^{(1)}+{\bf r}^{(2)}) + r  \cdot ({\bf e}_2^{(1)}+{\bf e}_2^{(2)}) +  {\bf m}^{(1)} + {\bf m}^{(2)} - r  \cdot ({\bf e}_1^{(1)}+{\bf e}_1^{(2)})  \times{\bf s}$ does not overflow $q$

we can gaurantee the addition is homomorphic over $\mathbb{Z}$. 

Since we want to be able to add $2^k$ number of ciphertexts together (and each ciphertext is mulitplied by an $\mathcal{F}_p$ element of 256 bits, which means for the total \#additions of 2^{k+8}),
we want
$r \cdot {\bf e} \times \sum_{i=1}^{2^{k+8}}{\bf r}^{(i)} + r  \cdot \sum_{i=1}^{2^{k+8}}{\bf e}_2^{(i)} +  \sum_{i=1}^{2^{k+8}}{\bf m}^{(i)} - r  \cdot \sum_{i=1}^{2^{k+8}}{\bf e}_1^{(i)}  \times{\bf s}$ to not overflow $q$.
That is
- $r > 2^{k+8}$
- $q > 2^{r+k+8} \beta_e\beta_r + 2^{r+k+8}\beta_{e_2} + 2^{k+8} + 2^{r + k + 8}\beta_{e_1}\beta_s$

Once an evalutated ciphertext is decrypted, we get a polynomial ${\bf m}' = \sum_{i=1}^{2^{k+8}} {\bf m}$. Evaluating ${\bf m}'$ at $2$ gives us
${\bf m}'(2) = \sum_{i=1}^{2^{k+8}} {\bf m}^{(i)}(2) = \sum_{i=1}^{2^{k+8}} m^{(i)} \in \mathbb{Z}$. One can lift this back to $\mathbb{F}_p$ via $\bmod p$.

## Security analysis
Both public key security and CPA security can be reduced from the ring-LWE problem. It is yet to be determined how hard each ring-LWE problem is. We perform the following analysis.
### PK security

For the lattice spanned by the row matrix of
$\begin{bmatrix}
q\cdot {\bf I}_n & 0 & 0 \\
{\bf a} &  {\bf I}_n & 0 \\
{\bf b} & 0 & 1 \\
\end{bmatrix}$
there exists a short vector $(-{\bf e}, {\bf s}, 1)$ with $\ell_2$ norm bouned by $\sqrt{n(2^{r}\beta_e)^2 + n\beta_s^2 + 1} \sim  2^{27.5}$. The Guassian heuristic length of the lattice is $\sqrt{\frac{dim}{2\pi e}}\det{}^{1/dim} = \sqrt{\frac{2n+1}{2\pi e}}q^{\frac{n}{2n+1}} \sim 2^{37}$.

For 128 bits security, a lattice reduction algorithm will not be able to find the short vector if
$c^{dim}\cdot \|\text{target_vector}\|_2 > \text{Gaussian_heuristic_length}$ for $c = 1.003$.

### CPA security


For the lattice spanned by the row matrix of
$\begin{bmatrix}
q\cdot {\bf I}_n & 0 & 0 \\
{\bf c}_1 &  {\bf I}_n & 0 \\
{\bf c}_2 & 0 & 1 \\
\end{bmatrix}$
there exist a short vector $(r  \cdot{\bf e}\times {\bf r} + r \cdot {\bf e}_2 + {\bf m} - r  \cdot{\bf e}_1 \times {\bf s}, -{\bf s}, 1)$. Observe that this vector is larger than the short vector in public key lattice -- that is, this attack is strickly worse than attacking the public key directly.

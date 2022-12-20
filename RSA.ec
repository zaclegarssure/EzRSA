require import AllCore Int.
require import IntDiv.
require import Number.
require (*--*) DiffieHellman PKE.
pragma +implicits.

const p: {int | IntDiv.prime p} as prime_p.


clone import DiffieHellman as DH.
import DDH FDistr.

   (** Construction: a PKE **)
 type pkey = int * int.
 type skey = int. 
 type plaintext = int.
 type ciphertext = int * int. (* For the moment we consider n in the public key*)

   (*clone import PKE_CPA as PKE with*)

clone import PKE as PKE_ with
 type pkey <- pkey,
 type skey <- skey,
 type plaintext <- plaintext,
 type ciphertext <- ciphertext.

module RSA: Scheme = {
  var p: int
  var q: int

  proc n(): int = {return p*q;}


  proc kg(): pkey * skey = {
  var sk;

  sk <$ dt;
  (*return ((g ^ sk, 2), sk);*)
    (* return ((d, n), e) *)
    return ((4, 17), 13);
  }

  proc enc(pk:pkey, m:plaintext): ciphertext = {
      var y, e, n;

      y <$ dt;

     (* Get the public key (e, n) *)
       (e, n) <- pk;

        return (m^e %% n, n);
  }

  proc dec(d:skey, c:ciphertext): plaintext option = {
      var y, n;
      (y, n) <- c;
      return Some (y^d %% n);
  }
  
  proc key_gen(): int = {
  return 3;
  }
}.

axiom test &m: Pr[RSA.key_gen() @ &m : res = 3] = 1%r.

 (** Correctness **)
hoare Correctness: Correctness(RSA).main: true ==> res.



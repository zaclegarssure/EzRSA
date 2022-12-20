require import AllCore Int.
require import IntDiv.
require import Number.
pragma +implicits.

 const p: {int | IntDiv.prime p} as prime_p.

module RSA = {
  var p: int
  var q: int

  proc n(): int = {return p*q;}

  proc key_gen(): int = {
    return 3;
  }
}.

axiom p_is_prime (RSA): prime RSA.p.
axiom key_is_prime RSA : prime(RSA.key_gen).

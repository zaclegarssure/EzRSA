require import AllCore List Ring RealExp ZModP IntDiv Bigalg StdRing StdOrder FloorCeil.
require import Distr DInterval DList DMap.
require import Poly.
require PKE.


op k: int.

axiom leq4_k: 4 <= k.

type pkey.
op p_n: pkey -> int.
op p_e: pkey -> int.

type skey.
op s_d: skey -> int.
op s_p: skey -> int.
op s_q: skey -> int.
op s_n: skey -> int = fun sk,
  s_p sk * s_q sk.

(* Specification of a least common multiple *)
op lcm_spec a b = fun z =>
(1 <= z /\ a %| z /\ b %| a)
  /\ (forall x, a %| x => b %| x => z <= x).

(* Inverse modulo n operator *)
op inv_mod x n = choiceb (fun y: int  => y * x %% n = 1) x.

(* Least common divisor between two numbers*)
op lcm a b = if (a, b) = (1, 1) then 1 else choiceb (gcd_spec a b) 0.

  (** They are generated by sampling in this distribution *)
type keypair = pkey * skey.
op keypairs: keypair distr.
axiom keypairsL: mu keypairs (fun s, true) = 1%r.

  (* Necessary conditions for (pk,sk) to be a valid keypair:
  *  - the public and private modulus are identical, and
  *  - the modulus is exactly k bits long                   *)
axiom valid_keypairs pk sk:
support keypairs (pk,sk) =>
p_n pk = s_n sk /\
  2^(k - 1) <= p_n pk < 2^k.

axiom primality_p sk:
prime (s_p sk).

axiom primality_q sk:
prime (s_q sk).

op pkey_eq pk1 pk2 = (p_n pk1 = p_n pk2) /\ (p_e pk1 = p_e pk2).
op skey_eq sk1 sk2 = (s_d sk1 = s_d sk2) /\ (s_p sk1 = s_p sk2) /\ (s_q sk1 = s_q sk2).

const SK: skey.
const PK: pkey.
axiom valid_global : support keypairs (PK, SK).

(* An adverseray trying to factor an rsa modulus n*)
module type RSAFP_adv = {
  proc factorize(n: int): int * int
}.

module RSAFP_game(Adv: RSAFP_adv) = {

  proc main() = {
  var p': int;
  var q': int;

    (p', q') <@ Adv.factorize(p_n PK);

      return ((p'*q') = p_n PK) && 1 < p' && p' < q' && q' < p_n PK;
  }
}.

module type RSAGOP_adv = {
  proc compute_GO(n: int): int
}.

module RSAGOP_game(Adv: RSAGOP_adv) = {

  proc main() = {
    var z: int;

    z <@ Adv.compute_GO(p_n PK);

    return z = (s_p SK - 1)*(s_q SK - 1);
  }
}.

module RSAGOP_using_RSAFP(A: RSAFP_adv): RSAGOP_adv = {
  proc compute_GO(n: int): int = {
  var p: int;
  var q: int;
    (p, q) <@ A.factorize(n);

      return (p-1)*(q-1);
  }
}.

(* RSAFP ==> RSAGOP *)
lemma PK_SK_equiv : (p_n PK = s_p SK * s_q SK).
    have SK_n : s_n SK = s_p SK * s_q SK.
    smt.
    rewrite - SK_n.
    smt all.
    qed.


(* TODO prove this *)
lemma n_factors_are_p_q : forall (p, q: int), p*q = p_n PK && 1 < p && p < q && q < p_n PK
    => (p = s_p SK && q = s_q SK) || (p = s_q SK && q = s_p SK).
proof.
    admit.
qed.

lemma RSAFP_to_RSAGOP_red (A <: RSAFP_adv) &m:
    Pr[RSAFP_game(A).main() @ &m : res] <= Pr[RSAGOP_game(RSAGOP_using_RSAFP(A)).main() @ &m : res].
proof.
   byequiv=>//.
   proc; inline *.
   wp.
   call (_: true).
   auto.
   move=> &1 &2 A_eq_m.
   simplify.
   split.
   smt.
   move=> same_A.
   move=> res_L res_R A_L A_R eq_res success_FP.
   have euh : (res_R.`1 = res_L.`1).
   smt.
   have ronaldinho_soccer : (res_R.`2 = res_L.`2).
   smt.
   auto.
   rewrite euh.
   rewrite ronaldinho_soccer.
   have haha : (p_n PK = (s_p SK)*(s_q SK)).
   smt all.
   (* Cleanup this mess a bit *)
   clear A &m &1 &2 A_eq_m same_A A_L A_R eq_res euh ronaldinho_soccer res_R.
   (* Here we use the previous lemma and it works *)
   (* Also make sure the timeout is big enough, it took ~6 seconds on my computer *)
   smt [+"Z3"] all timeout=10.
qed.


(*
module FactGOP(AdvGop : RSA_GOP_adv) : RSA_factoring_adv = {
  proc factorize(pk: pkey): int * int = {
    var ply: Poly.ZPoly;
    return (9, 9);
    
  }
}.*)

module type RSAKRP_adv = {
  proc recover(n: int, e: int): int
}.

module RSAKRP_game(A: RSAKRP_adv) = {
  proc main(): bool = {
    var d': int;
    d' <@ A.recover(p_n PK, p_e PK);
    return d' = s_d SK;
  }
}.


module type RSADP_adv = {
  proc decrypt(n: int, e: int, y: int): int
}.

module RSADP_game(A: RSADP_adv) = {
  proc main(): bool = {
    var x: int;
    var y: int;
    var z: int;

    x <$ [0..(2^k)];
    y <- (x ^ p_e PK) %% (p_n PK);

    z <@ A.decrypt(p_n PK, p_e PK, y);

    return x = z;
  }
}.

module RSADP_using_RSAKRP(A: RSAKRP_adv): RSADP_adv = {
  proc decrypt(n: int, e: int, y: int): int = {
  var d: int;
    var x: int;
  d <@ A.recover(p_n PK, p_e PK);
  x <- (y ^ d) %% (p_n PK);
  return x;
  }
}.

 (* RSAKRP ==> RSADP *)
section.
declare module A <: RSAKRP_adv.
  (*lemma red2: equiv[RSA_factoring_game(A).main ~ RSA_GOP(B(A)).main : true ==> (res{1} => res{2})].
  proof.
  assume.
  *)

  (* TODO prove it*)
lemma RSAKRP_to_RSADP_red : equiv[RSAKRP_game(A).main ~ RSADP_game(RSADP_using_RSAKRP(A)).main : true ==> res{1} => res{2}].
    admit.
  qed.

  end section.

(* An adverseray trying to compute the Carmicheal value of n *)
module type RSAEMP_adv = {
  proc lambda(n: int): int
}.

module RSAEMP_game(Adv: RSAEMP_adv) = {
  proc main() = {
  var z: int;

  z <@ Adv.lambda(p_n PK);

  return ((z = lcm (s_p SK) (s_q SK)) && z <> 0);
  }
}.

(* At this point we have to implement the factorization using lambda...
    module EMP_using_LMBDA(A: RSA_EMP_adv): RSA_EMP_adv = {
    proc compute_GO(pk: pkey): int = {
    var p: int;
    var q: int;
    z <@ A.lambda(pk);

    return (p-1)*(q-1);
    }
    }.
*)

(* EMP ==> RSAFP*)
(* TODO: EMPTY *)

module RSAEMP_using_RSAKRP(A: RSAKRP_adv): RSAEMP_adv = {
  proc lambda(n: int): int = {
    var d: int;
    var e: int;
    e <- p_e PK;
    d <@ A.recover(n, e);

  return e * d - 1;
  }
}.

(* RSAKRP ==> EMP *)
section.
declare module A <: RSAKRP_adv.
  (* TODO prove it*)
lemma RSAKRP_to_RSAEMP_red : equiv[RSAKRP_game(A).main ~ RSAEMP_game(RSAEMP_using_RSAKRP(A)).main : true ==> res{1} => res{2}].
    admit.
  qed.

  end section.


 module RSAKRP_using_RSAGOP(A: RSAGOP_adv): RSAKRP_adv = {
    proc recover(n: int, e: int): int = {
   var z: int;
   var d: int;
     z <@ A.compute_GO(n);
     d <- inv_mod e z;

     return d;
    }
  }.

 (* RSAGOP ==> RSAKRP *)
  section.
  declare module A <: RSAGOP_adv.

    (* TODO prove it*)
lemma RSAGOP_to_RSAKRP_red : equiv[RSAGOP_game(A).main ~ RSAKRP_game(RSAKRP_using_RSAGOP(A)).main : true ==> res{1} => res{2}].
    admit.
  qed.

  end section.

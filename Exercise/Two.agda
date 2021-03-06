-- TOTAL MARK: 59/60
{-# OPTIONS --type-in-type #-}
{-# OPTIONS --allow-unsolved-metas #-}

module Exercise.Two where

open import Lib.Basics
open import Lib.Indexed       -- important stuff in here!
open import Lib.Cat.Category
open import Lib.Cat.Functor
open import Lib.Cat.NatTrans
open import Lib.Cat.Monad
open import Lib.Cat.Adjunction
open import Lib.Nat

open import Exercise.One

------------------------------------------------------------------------------
-- CATEGORIES OF INDEXED OBJECTS AND ARROWS
------------------------------------------------------------------------------

-- We fix an underlying category and a set I for "index"...

module _ {Obj : Set}{Arr : Obj -> Obj -> Set}(I : Set)(C : Category Arr) where

  open Category C

  -- ... and now your job is to build a new category whose
  -- objects are I-indexed families of underlying objects, and whose
  -- arrows are index-respecting families of underlying arrows

  _-C>_ : Category {I -> Obj} \ S T -> (i : I) -> Arr (S i) (T i)
  _-C>_ = record
            { idArr = \ i -> idArr
            ; _-arr-_ = \ f1 f2 i -> f1 i -arr- f2 i 
            ; idArr-arr- = \ f -> ext \ i -> idArr-arr- (f i) 
            ; _-arr-idArr = \ f -> ext (\ i -> f i -arr-idArr)
            ; assoc-arr- = \ f g h -> ext \ i -> assoc-arr- (f i) (g i) (h i)
            }


-- Now we give you a function f : I -> J between two index sets.

module _ {Obj : Set}{Arr : Obj -> Obj -> Set}{I J : Set}
       (f : I -> J)(C : Category Arr) where

  open Category C
  open Functor

  -- Show that you get a functor from J-indexed things to I-indexed things.

  Reindex : Functor (J -C> C) (I -C> C) (f -_)
  Reindex = record
    { map = \ x i -> x (f i) ;
      mapidArr = refl ;
      map-arr- = \ x g -> refl }

-- MARK: 4/4

------------------------------------------------------------------------------
-- FUNCTORIALITY OF ALL
------------------------------------------------------------------------------

-- We have All in the library. Show that it is a functor from
-- element-indexed sets to list-indexed sets.

module _ where

  open Functor

  all : {I : Set}{P Q : I -> Set} ->
        [ P -:> Q ] ->
        [ All P -:> All Q ]
  all f [] [] = []
  all f (i ,- is) (p ,- ps) = f i p ,- all f is ps

  helper1 : forall {I} {A : I -> Set} (is : List I)
                 (as : All A is) ->
          all (\ i x -> x) is as == as
  helper1 [] [] = refl
  helper1 (i ,- is) (a ,- as) rewrite helper1 is as = refl

  helper2 : forall {I} {A B C : I -> Set} {f : (i : I) -> A i -> B i}
                 {g : (i : I) -> B i -> C i} (is : List I) (as : All A is) ->
          all (\ i a -> g i (f i a)) is as == all g is (all f is as)
  helper2 [] [] = refl
  helper2 {f = f} {g = g} (i ,- is) (a ,- as) = g i (f i a) ,-_ $= helper2 is as   


  ALL : (I : Set) -> Functor (I -C> SET) (List I -C> SET) All
  ALL I = record
          { map = all;
            mapidArr = ext \ is -> ext (\ as -> helper1 is as) ;
            map-arr- = \ f g -> ext \ is -> ext \ as -> helper2 is as  }


-- MARK: 6/6

------------------------------------------------------------------------------
-- ALL BY TABULATION
------------------------------------------------------------------------------

-- The list membership relation is given by thinning from singletons.

_<-_ : {I : Set} -> I -> List I -> Set
i <- is = (i ,- []) <: is

-- If every element of a list satisfies P, you should be able to
-- collect all the Ps.

tabulate : {I : Set}{P : I -> Set}(is : List I) ->
             [ (_<- is) -:> P ] -> All P is
tabulate [] f = []
tabulate (i ,- is) f = f i (os oe) ,- tabulate is \ i -> o' - f i 


module _ (I : Set) where  -- fix an element set and open handy kit
  open Category (I -C> SET)
  open Functor
  open NaturalTransformation

  -- Show that the functional presentation of "each element is P"
  -- also gives you a functor.

  AllMem : Functor (I -C> SET) (List I -C> SET) \ P is -> [ (_<- is) -:> P ]
  AllMem = record
         { map = \ f is g i th -> f i (g i th) ;
           mapidArr = refl ;
           map-arr- = \ f g -> refl }

  -- Prove that tabulate is natural.

  helper : forall {I} {X Y : I -> Set} (f : (i : I) -> X i -> Y i)
                (is : List I) (g : (i : I) -> i ,- [] <: is -> X i) ->
         all f is (tabulate is g) == tabulate is (\ i th -> f i (g i th))
  helper f [] g = refl
  helper f (i ,- is) g rewrite helper f is (\ i th -> g i (o' th)) = refl 

  tabulateNT : NaturalTransformation AllMem (ALL I)
  transform tabulateNT _ = tabulate
  natural tabulateNT = \ f -> ext (\ is -> ext (\ g -> helper f is g)) 

-- MARK: 8/8


------------------------------------------------------------------------------
-- 26 November 2018 -- the adventure continues
------------------------------------------------------------------------------

module _ {Obj : Set}{Arr : Obj -> Obj -> Set}{I : Set}(C : Category Arr) where
  open Category C
  open Functor

  -- Show that you can get a functor from  (I -C> C) back to C, just
  -- by picking an index.

  Point : (i : I) -> Functor (I -C> C) C \ X -> X i
  Point i = record
            { map = \ f -> f i  ;
              mapidArr = refl ;
              map-arr- = \ f g -> refl }

module _ (I : Set) where
  open Category (I -C> SET)
  open Functor
  open NaturalTransformation

  -- Prove that the "select" function from Exercise.One is natural.

  selectNT : {is js : List I}(th : is <: js) ->
             NaturalTransformation
               (ALL I -Func- Point SET js)
               (ALL I -Func- Point SET is)
  transform (selectNT th) X = select th
  natural (selectNT th) f = ext \ ps -> prf th f ps where
      prf : forall {I} {is js : List I} {X Y : I -> Set} (th : is <: js)
             (f : (i : I) -> X i -> Y i) (ps : All X js) ->
            all f is (select th ps) == select th (all f js ps)
      prf (o' th) f (p ,- ps) =  prf th f ps 
      prf (os th) f (p ,- ps) =  _ ,-_ $= prf th f ps
      prf oz f [] = refl 


  -- Show that tabulation fuses with selection.

  selectTabulate : {I : Set}{P : I -> Set}{is js : List I}
      (th : is <: js)(f : [ (_<- js) -:> P ]) ->
      select th (tabulate js f) == tabulate is \ i x -> f i (x -<- th)
  selectTabulate (o' th) f = selectTabulate th \ i ph -> f i (o' ph)
  selectTabulate (os th) f =
    reff (\ p ps -> p ,- ps)
    =$= ((\ x -> f _ x) $= ((\ x -> os x) $= sym (oe-unique (oe -<- th))))
    =$= selectTabulate th \ i ph -> f i (o' ph)
  selectTabulate oz f = refl

  -- Construct the proof that all elements of a list have the property
  -- of being somewhere in the list.

  positions : (is : List I) -> All (_<- is) is
  positions is = tabulate is \ i -> id

-- MARK: 6/6

  -- Construct a natural transformation which extracts the only element
  -- from an All P (i ,- [])

  getOnlyOne : {I : Set}{i : I}{P : I -> Set} ->
               All P (i ,- []) -> P i
  getOnlyOne (p ,- ps) = p

  onlyNT : NaturalTransformation
            (ALL I -Func- Reindex (_,- []) SET)
            (ID (I -C> SET))
  onlyNT = record
           { transform = \ P i -> getOnlyOne;
             natural = \ f -> ext \ i -> ext \ {(p ,- []) -> refl }}

-- MARK: 2/2

  -- From these components, assemble the natural transformation which projects
  -- one element from a bunch. That is, if we have (x : i <- is) and we have
  -- Ps for all the is, then we should certainly have a P i.

  projectNT : {i : I}{is : List I}(x : i <- is) ->
              NaturalTransformation (ALL I -Func- Point SET is) (Point SET i)
  transform (projectNT x) P ps = transform onlyNT P _ (transform (selectNT x) P ps)
  natural (projectNT x) f = ext \ ps ->
    f _ (getOnlyOne (select x ps))

    =[ natural onlyNT f =$ _ =$ (select x ps) >=

    getOnlyOne (all f _ (select x ps))

    =[ getOnlyOne $= (natural (selectNT x) f =$ ps) >=

    getOnlyOne (select x (all f _ ps))

    [QED]

-- MARK: 3/3

  -- Show that tabulating projections is the identity.


  tabulateProject : {P : I -> Set}{is : List I}(ps : All P is) ->
   tabulate is (\ i x -> transform (projectNT x) P ps) == ps
  tabulateProject [] = refl
  tabulateProject (p ,- ps) = p ,-_ $= tabulateProject ps


  -- Show that projecting from a tabulation applies the tabulated function.

  projectTabulate : {P : I -> Set}{is : List I}
    (f : (i : I) -> i <- is -> P i)
    {i : I}(x : i <- is) ->
    transform (projectNT x) P (tabulate is f) == f i x
  projectTabulate f (o' x) = projectTabulate _ x
  projectTabulate f (os x) = f _ $= (os $= sym (oe-unique x)) 


  -- A useful way to show that two "All" structures are equal is to show that
  -- they agree at each projection. Make it so! Hint: tabulateProject.

  eqAll : {P : I -> Set}{is : List I}{ps0 ps1 : All P is} ->
    ((i : I)(x : i <- is) ->
      transform (projectNT x) P ps0 == transform (projectNT x) P ps1) ->
    ps0 == ps1
  eqAll {ps0 = ps0}{ps1 = ps1} q =
    ps0
      =< tabulateProject ps0 ]=
    tabulate _ (\ i x -> getOnlyOne (select x ps0))
      =[ tabulate _ $= (ext \ i -> ext \ x -> q i x) >=
    tabulate _ (\ i x -> getOnlyOne (select x ps1))
      =[ tabulateProject ps1  >=
    ps1
    [QED]

-- MARK: 7/7

------------------------------------------------------------------------------
-- HOW TO CUT THINGS UP
------------------------------------------------------------------------------

record _<|_ (O{-utside-} I{-nside-} : Set) : Set where
  constructor _<!_
  field
    Cuts    : O -> Set  -- for every Outside, there is a set of ways to cut it
    pieces  : {o : O} -> Cuts o -> List I
                        -- into a bunch of pieces which are Inside

-- This information amounts to giving an indexed container with finitely
-- many positions. As a consequence, we can use All to collect the
-- substructures which fill the pieces inside.

module _ {O I : Set} where

  open Category
  open Functor
  open _<|_

  [[_]]Cr : O <| I -> (I -> Set)   -- what's filling the insides?
                   -> (O -> Set)
  [[ Cu <! ps ]]Cr P o =      Sg (Cu o) \ c   -- choose your cut
                           -> All P (ps c)    -- then fill all the insides

  -- Extend [[_]]Cr to a Functor.

  [[_]]CrF : (F : O <| I) ->
               Functor (I -C> SET) (O -C> SET) [[ F ]]Cr
  [[ Cu <! ps ]]CrF = record
    { map = \ {f o (cu , as) -> cu , all f (ps cu) as }
    ; mapidArr = ext \ o -> ext \ { (cu , as) ->
      (cu ,_) $= (mapidArr (ALL _) =$ ps cu =$= reff as) }
    ; map-arr- = \ f g -> ext \ o -> ext \ { (cu , as) ->
      (cu ,_) $= (map-arr- (ALL _) f g =$ ps cu =$= reff as) }
    }

-- MARK: 2/2

  -- Meanwhile, there is a concrete way to represent natural transformations
  -- between two such functors.
  
  Cutmorph : (F G : O <| I) -> Set
  Cutmorph (Cu <! ps) G =
    (o : O)(cu : Cu o)             -- given a source cut
      -> [[ G ]]Cr (_<- ps cu) o   -- choose a target cut, and say which source
                                   -- piece goes in each target position

  module _ (F G : O <| I) where

    open NaturalTransformation
    module GF = Functor [[ G ]]CrF

    -- Show that every Cutmorph induces a natural transformation.
    -- Proving it is natural is an opportunity to deploy eqAll.

    CutmorphNT : Cutmorph F G ->  NaturalTransformation  [[ F ]]CrF  [[ G ]]CrF
    transform (CutmorphNT m) P o (cu , ps) =
      GF.map (\ i x -> transform (projectNT I x) P ps) o (m o cu)
    natural (CutmorphNT m) f =
      ext \ o -> ext \ {(cu , ps) -> {!natCutHelper!} } 
        

-- F: right transformation, but no naturality proof

-- MARK: 1/2 (one more for the naturality proof)

    -- Extract a Cutmorph from an arbitrary natural transformation by choosing
    -- a suitable element type.

    ntCutmorph : NaturalTransformation  [[ F ]]CrF  [[ G ]]CrF  -> Cutmorph F G
    ntCutmorph k = \ o cu -> transform k _ o (cu , positions _ _)


  -- Construct identity and composition for Cutmorphs. Hint: you've done the
  -- hard work already.

  idCutmorph : {F : O <| I} -> Cutmorph F F
  idCutmorph = \ o cu -> cu , positions _ _

  _-Cutmorph-_ : {F G H : O <| I} -> Cutmorph F G -> Cutmorph G H -> Cutmorph F H
  (fg -Cutmorph- gh) o cu with fg o cu
  (fg -Cutmorph- gh) o cu | cu' , snd with gh o cu'
  (fg -Cutmorph- gh) o cu | cu' , snd | cu'' , snd1 =
   cu'' , all (\ i x -> getOnlyOne I (select x snd)) _ snd1


-- MARK: 4/4

  -- We have left the following goal commented out, because it involves more heat
  -- than light.
  -- CUTMORPH : Category Cutmorph
  -- CUTMORPH = ?

  --TODO use tool for categories here?

-- F: Note that we are not asking you to prove the laws! (It gets too ugly.)

------------------------------------------------------------------------------
-- HOW TO CUT THINGS UP INTO LOTS OF LITTLE TINY PIECES
------------------------------------------------------------------------------

module _ {I : Set}(F : I <| I) where

  -- If the insides have the same index type as the outsides, we can cut and
  -- cut again.

  data Tree (X : I -> Set)(i : I) : Set where
    leaf : X i -> Tree X i
    <_> : [[ F ]]Cr (Tree X) i -> Tree X i

  -- The following wrap the constructors as arrows in I -C> SET.
  
  iLeaf : {X : I -> Set} -> [ X -:> Tree X ]
  iLeaf i = leaf
  iNode : {X : I -> Set} -> [ [[ F ]]Cr (Tree X) -:> Tree X ]
  iNode i = <_>

  module _ {X Y : I -> Set}             -- Suppose we can turn ...
           (l : [ X -:> Y ])            -- ... leaves into Ys, and ...
           (n : [ [[ F ]]Cr Y -:> Y ])  -- ... nodes made of Ys into Ys.
         where

    -- Show that we can turn whole trees into Ys.
    -- You will need to inline functoriality of All to get the
    --   termination checker to shut up.

    treeIter : [ Tree X -:> Y ]
    allTreeIter : [ All (Tree X) -:> All Y ]
    treeIter i (leaf x) = l i x
    treeIter i < cu , ts > = n i (cu , allTreeIter _ ts)
    allTreeIter [] [] = []
    allTreeIter (i ,- is) (t ,- ts) = treeIter i t ,- allTreeIter is ts


-- MARK: 5/5

  module _ where
    open Category (I -C> SET)

    -- Use treeIter, rather than pattern matching, to construct the following
    -- operation which should preserve nodes and graft on more tree at the leaves.

    treeBind : {X Y : I -> Set} -> [ X -:> Tree Y ] -> [ Tree X -:> Tree Y ]
    treeBind k = treeIter k iNode

    -- Use treeBind to implement "map" and "join" for trees.
    -- They're one-liners.

    tree : {X Y : I -> Set} -> [ X -:> Y ] -> [ Tree X -:> Tree Y ]
    tree f = treeBind (f -arr- iLeaf)

    treeJoin : {X : I -> Set} -> [ Tree (Tree X) -:> Tree X ]
    treeJoin = treeBind idArr


    -- Show that replacing leaves by leaves and nodes by nodes achieves little.
    -- This will need a proof by induction.

    idHelper :  {X : I -> Set} (x : I)
                    (t : Tree X x) ->
             treeIter (\ i -> leaf) (\ i -> <_>) x t == t

    allIdHelper :  {X : I -> Set} (xs : List I)
                    (ts : All (Tree X ) xs) ->
             allTreeIter (\ i -> leaf) (\ i -> <_>) xs ts == ts

    idHelper i (leaf x) = refl
    idHelper i < cu , ts > = <_> $= ((cu ,_ $= allIdHelper _ ts))

    allIdHelper [] [] = refl
    allIdHelper (x ,- xs) (t ,- ts) =
      reff (\ y ys -> y ,- ys) =$= idHelper x t =$= allIdHelper xs ts 

    treeIterId : {X : I -> Set} -> treeIter (iLeaf {X = X}) iNode == idArr
    treeIterId = ext \ i -> ext \ t -> idHelper i t


  -- The following result will be of considerable assistance.

  module _ {W X Y : I -> Set}
           (k : [ W -:> Tree X ])       -- how to grow more tree
           (l : [ X -:> Y ])            -- how to eat leaves
           (n : [ [[ F ]]Cr Y -:> Y ])  -- how to eat nodes
           where
    open Category (I -C> SET)

    -- Show that growing a tree with treeBind then eating the result
    -- gives the same as eating the original with more eating at the leaves.

    bindHelper : (i : I) (t : Tree W i) ->
             treeIter l n i (treeIter k (\ i1 -> <_>) i t) ==
             treeIter (\ i1 a -> treeIter l n i1 (k i1 a)) n i t
    allBindHelper : (is : List I) (ts : All (Tree W) is) ->
             allTreeIter l n is (allTreeIter k (\ i1 -> <_>) is ts) ==
             allTreeIter (\ i1 a -> treeIter l n i1 (k i1 a)) n is ts

    bindHelper i (leaf x) = refl
    bindHelper i < cu , ts > = n i $= ((\ x -> cu , x) $= allBindHelper _ ts)
    allBindHelper [] [] = refl
    allBindHelper (i ,- is) (t ,- ts) =
      reff (\ x xs -> x ,- xs) =$= bindHelper i t =$= allBindHelper is ts

    treeBindIter : (treeBind k -arr- treeIter l n)
                     ==
                   treeIter (k -arr- treeIter l n) n
    treeBindIter = ext \ i -> ext \ t -> bindHelper i t where 


  -- Suitably tooled up, go for the win.

  module _  where
    open Category (I -C> SET)
    open Functor
    open NaturalTransformation
    open Monad

    -- You have implemented "map" and "join".
    -- Prove that you have a functor and a monad.

    TREE : Functor (I -C> SET) (I -C> SET) Tree
    map TREE = tree
    mapidArr TREE = treeIterId
    map-arr- TREE = \ f g ->
       tree (f -arr- g)
       =< treeBindIter
       (f -arr- iLeaf) (g -arr- iLeaf) iNode ]=
       tree f -arr- tree g
       [QED]


    treeMonad : Monad TREE
    transform (returnNT treeMonad) X = iLeaf
    natural (returnNT treeMonad) = \ f -> refl
    transform (joinNT treeMonad) X = treeJoin

    natural (joinNT treeMonad) = \ f -> 
     treeJoin -arr- tree f
     =[ treeBindIter idArr (f -arr- iLeaf) iNode >=
     treeBind (tree f)
     =< treeBindIter (tree f -arr- iLeaf) idArr iNode ]=
     tree (tree f) -arr- treeJoin
     [QED]
    returnJoin treeMonad = refl

    mapReturnJoin treeMonad =
     tree iLeaf -arr- treeJoin
     =[ treeBindIter (iLeaf -arr- iLeaf) idArr iNode >=
     tree idArr
     =[ mapidArr TREE >=
     idArr
     [QED]

    joinJoin treeMonad =
     treeJoin -arr- treeJoin
     =[ treeBindIter idArr idArr iNode >=
     treeBind treeJoin
     =< treeBindIter (treeJoin -arr- iLeaf) idArr iNode ]=
     tree treeJoin -arr- treeJoin
     [QED]

-- MARK: 9/9

------------------------------------------------------------------------------
-- AND RELAX
------------------------------------------------------------------------------

-- If "outsides" are a numerical size z,
-- we might cut them into two pieces whose sizes add up to z.

NatCut : Nat <| Nat
NatCut = (\ z -> Sg Nat \ x -> Sg Nat \ y -> (x +N y) == z)
      <! (\ { (x , y , _) -> x ,- y ,- []})

twoToThe : Nat -> Nat
twoToThe zero     = 1
twoToThe (suc n)  = twoToThe n +N twoToThe n

-- You have to make a big tree out of Xs, but you have only an X of size 1.
-- There is more than one right answer.

bigTree : (X : Nat -> Set) -> X 1 -> (n : Nat) -> Tree NatCut X (twoToThe n)
bigTree X x zero = leaf x
bigTree X x (suc n) =
  < (twoToThe n , twoToThe n , refl) ,
     bigTree X x n ,-
     bigTree X x n ,-
     [] >

-- MARK: 2/2

-- We'll see more of Tree and NatCut next time...


------------------------------------------------------------------------------
-- END OF EXERCISE TWO
------------------------------------------------------------------------------

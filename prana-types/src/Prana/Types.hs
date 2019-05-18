{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE MagicHash #-}
{-# LANGUAGE DeriveGeneric #-}

-- |

module Prana.Types
  ( module Prana.Types
  , module Prana.PrimOp.Type
  ) where

import           Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as S8
import           Data.Flat
import           Data.Int
import           Data.Map.Strict (Map)
import           Data.Word
import           GHC.Generics
import           Prana.PrimOp.Type

data GlobalBinding
  = GlobalStringLit !GlobalVarId !ByteString
  | GlobalNonRec !GlobalVarId !Rhs
  | GlobalRec ![(GlobalVarId, Rhs)]
  deriving (Show, Eq, Generic)

data LocalBinding
  = LocalNonRec !LocalVarId !Rhs
  | LocalRec ![(LocalVarId, Rhs)]
  deriving (Show, Eq, Generic)

data Expr
  = AppExpr !SomeVarId ![Arg]
  | ConAppExpr !DataConId ![Arg] ![Type]
  | OpAppExpr !Op ![Arg] !(Maybe TypeId)
  | CaseExpr !Expr !LocalVarId !Alts
  | LetExpr !LocalBinding !Expr
  | LitExpr !Lit
  deriving (Show, Eq, Generic)

-- The Maybe Expr is the DEFAULT case.
data Alts
  = PolymorphicAlt !Expr
    -- ^ Polymorphic value, we force it.
  | DataAlts !TyCon ![DataAlt] !(Maybe Expr)
    -- ^ For regular ADT types.
  | MultiValAlts !Int ![DataAlt] !(Maybe Expr)
    -- ^ For unboxed sums and unboxed tuples.
  | PrimAlts !PrimRep ![LitAlt] !(Maybe Expr)
    -- ^ Primitive value.
  deriving (Show, Eq, Generic)

data DataAlt =
  DataAlt
    { dataAltCon :: !DataConId
    , dataAltBinders :: ![LocalVarId]
    , dataAltExpr :: !Expr
    }
  deriving (Show, Eq, Generic)

data LitAlt =
  LitAlt
    { litAltLit :: !Lit
    , litAltBinders :: ![LocalVarId]
    , litAltExpr :: !Expr
    }
  deriving (Show, Eq, Generic)

data Rhs
  = RhsClosure !Closure
  | RhsCon !Con
  deriving (Show, Eq, Generic)

data Con =
  Con
    { conDataCon :: !DataConId
    , conArg :: ![Arg]
    }
  deriving (Show, Eq, Generic)

data Closure =
  Closure
    { closureFreeVars :: ![LocalVarId]
    , closureUpdateFlag :: !UpdateFlag
    , closureParams :: ![LocalVarId]
    , closureExpr :: !Expr
    } deriving (Show, Eq, Generic)

newtype GlobalVarId = GlobalVarId Int64
  deriving (Show, Eq, Generic, Ord)
instance Flat GlobalVarId

newtype LocalVarId = LocalVarId Int64
  deriving (Show, Eq, Generic, Ord)
instance Flat LocalVarId

data SomeVarId
  = SomeLocalVarId !LocalVarId
  | SomeGlobalVarId !GlobalVarId
  | WiredInVal !WiredInVal
  deriving (Show, Eq, Generic)

data WiredInVal
  = WiredIn_coercionToken#
  | WiredIn_void#
  | WiredIn_realWorld#
  | WiredIn_nullAddr#
  | WiredIn_seq
  | WiredIn_magicDict
  | WiredIn_proxy#
  | WiredIn_patError
    -- TODO:
    -- Design decision required.
    --
    -- This is something that is actually defined, but it's used by
    -- integer-simple before it's actually defined. I think this may
    -- be a "known-key" rather than "wired-in". I think this can
    -- simply be translated back to its respective GlobalVarId,
    -- although I'm not exactly sure when.
  deriving (Show, Eq, Generic)

data SomeTypeId

data TypeId
  = TypeId
      { typeIdInt :: !Int64
      }
  | WiredInType !WiredInType
  deriving (Show, Eq, Generic, Ord)
instance Flat TypeId

data WiredInType
  = WiredIn_CharPrimTyConName
  | WiredIn_IntPrimTyConName
  | WiredIn_Int32PrimTyConName
  | WiredIn_Int64PrimTyConName
  | WiredIn_WordPrimTyConName
  | WiredIn_Word32PrimTyConName
  | WiredIn_Word64PrimTyConName
  | WiredIn_AddrPrimTyConName
  | WiredIn_FloatPrimTyConName
  | WiredIn_DoublePrimTyConName
  | WiredIn_StatePrimTyConName
  | WiredIn_ProxyPrimTyConName
  | WiredIn_RealWorldTyConName
  | WiredIn_ArrayPrimTyConName
  | WiredIn_ArrayArrayPrimTyConName
  | WiredIn_SmallArrayPrimTyConName
  | WiredIn_ByteArrayPrimTyConName
  | WiredIn_MutableArrayPrimTyConName
  | WiredIn_MutableByteArrayPrimTyConName
  | WiredIn_MutableArrayArrayPrimTyConName
  | WiredIn_SmallMutableArrayPrimTyConName
  | WiredIn_MutVarPrimTyConName
  | WiredIn_MVarPrimTyConName
  | WiredIn_TVarPrimTyConName
  | WiredIn_StablePtrPrimTyConName
  | WiredIn_StableNamePrimTyConName
  | WiredIn_CompactPrimTyConName
  | WiredIn_BcoPrimTyConName
  | WiredIn_WeakPrimTyConName
  | WiredIn_ThreadIdPrimTyConName
  | WiredIn_EqPrimTyConName
  | WiredIn_EqReprPrimTyConName
  | WiredIn_EqPhantPrimTyConName
  | WiredIn_VoidPrimTyConName
  | WiredIn_UnboxedTuple !Int
  deriving (Show, Eq, Generic, Ord)
instance Flat WiredInType

newtype ConIndex =
  ConIndex
    { conIndexInt :: Int64
    }
  deriving (Show, Eq, Generic, Ord)
instance Flat ConIndex

data DataConId
  = DataConId !TypeId !ConIndex
  | UnboxedTupleConId !Int
  deriving (Show, Eq, Generic, Ord)
instance Flat DataConId

data UpdateFlag
  = ReEntrant
  | Updatable
  | SingleEntry
  deriving (Show, Eq, Generic)

data Type =
  Type
  deriving (Show, Eq, Generic)

data Arg
  = VarArg !SomeVarId
  | LitArg !Lit
  deriving (Show, Eq, Generic)

data Lit
  = CharLit !Char
  | StringLit !ByteString
  | NullAddrLit
  | IntLit !Int
  | Int64Lit !Int64
  | WordLit !Word
  | Word64Lit !Word64
  | FloatLit !Float
  | DoubleLit !Double
  | IntegerLit !Integer
  | LabelLit
  deriving (Show, Eq, Generic)

data PrimRep
  = VoidRep
  | LiftedRep
  | UnliftedRep -- ^ Unlifted pointer
  | IntRep -- ^ Signed, word-sized value
  | WordRep -- ^ Unsigned, word-sized value
  | Int64Rep -- ^ Signed, 64 bit value (with 32-bit words only)
  | Word64Rep -- ^ Unsigned, 64 bit value (with 32-bit words only)
  | AddrRep -- ^ A pointer, but /not/ to a Haskell value (use '(Un)liftedRep')
  | FloatRep
  | DoubleRep
  | VecRep Int PrimElemRep -- ^ A vector
  deriving (Eq, Show, Generic)

data PrimElemRep
  = Int8ElemRep
  | Int16ElemRep
  | Int32ElemRep
  | Int64ElemRep
  | Word8ElemRep
  | Word16ElemRep
  | Word32ElemRep
  | Word64ElemRep
  | FloatElemRep
  | DoubleElemRep
  deriving (Eq, Show, Generic)

data TyCon =
  TyCon
  deriving (Show, Eq, Generic)

data Op
  = PrimOp PrimOp
  | OtherOp
  deriving (Show, Eq, Generic)

displayName :: Name -> String
displayName (Name pkg md name u) = S8.unpack (pkg <> ":" <> md <> "." <> name <> ext)
  where ext = case u of
                Exported -> ""
                Unexported i -> "_" <> S8.pack (show i) <> ""

-- | A syntactically globally unique name.
data Name =
  Name
    { namePackage :: {-# UNPACK #-}!ByteString
    , nameModule :: {-# UNPACK #-}!ByteString
    , nameName :: {-# UNPACK #-}!ByteString
    , nameUnique :: !Unique
    }
  deriving (Show, Ord, Eq, Generic)
instance Flat Name

-- | Names can be referred to by their package-module-name
-- combination. However, if it's a local name, then we need an extra
-- unique number to differentiate different instances of the same name
-- string in the same module (e.g. @xs@).
data Unique
  = Exported
  | Unexported !Int64
  deriving (Show, Ord, Eq, Generic)
instance Flat Unique

data Index =
  Index
    { indexGlobals :: Map Name GlobalVarId
    , indexLocals :: Map Name LocalVarId
    , indexDataCons :: Map Name DataConId
    , indexTypes :: Map Name TypeId
    }
  deriving (Generic, Show)
instance Flat Index

data ReverseIndex =
  ReverseIndex
    { reverseIndexDataCons :: Map DataConId Name
    , reverseIndexGlobals :: Map GlobalVarId Name
    , reverseIndexLocals :: Map LocalVarId Name
    , reverseIndexTypes :: Map TypeId Name
    , reverseIndexIndex :: Index
    }

--------------------------------------------------------------------------------
-- Flat instances

instance Flat GlobalBinding
instance Flat Rhs
instance Flat UpdateFlag
instance Flat Expr
instance Flat Arg
instance Flat SomeVarId
instance Flat Type
instance Flat Op
instance Flat Alts
instance Flat LocalBinding
instance Flat Lit
instance Flat WiredInVal
instance Flat TyCon
instance Flat DataAlt
instance Flat PrimRep
instance Flat PrimElemRep
instance Flat LitAlt
instance Flat Closure
instance Flat Con

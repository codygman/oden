module Oden.Compiler.Validation.TypedValidationSpec where

import           Test.Hspec

import           Oden.Compiler.Validation.Typed

import           Oden.Core.Typed      as Typed
import           Oden.Core.Definition
import           Oden.Core.Expr
import           Oden.Core.Package

import           Oden.Identifier
import           Oden.Metadata
import           Oden.QualifiedName
import           Oden.SourceInfo
import           Oden.Type.Polymorphic

import qualified Data.Set as Set

import           Oden.Assertions

missing :: Metadata SourceInfo
missing = Metadata Missing

typeUnit, typeString, typeInt, typeIntSlice :: Type
typeUnit = TCon (Metadata Predefined) (nameInUniverse "unit")
typeString = TCon (Metadata Predefined) (nameInUniverse "string")
typeInt = TCon (Metadata Predefined) (nameInUniverse "int")
typeIntSlice = TSlice missing typeInt

canonical :: TypedExpr -> CanonicalExpr
canonical e = (Forall missing [] Set.empty (typeOf e), e)

unitExpr :: TypedExpr
unitExpr = Literal missing Unit typeUnit

strExpr :: TypedExpr
strExpr = Literal missing (String "hello") typeString

intExpr :: Integer -> TypedExpr
intExpr n = Literal missing (Int n) typeInt


letExpr :: Identifier -> TypedExpr -> TypedExpr -> TypedExpr
letExpr n value body = Let missing (NameBinding missing n) value body (typeOf body)

fnExpr :: Identifier -> TypedExpr -> TypedExpr
fnExpr n body = Fn missing (NameBinding missing n) body (TFn missing typeString (typeOf body))

block :: [TypedExpr] -> TypedExpr
block exprs = Block missing exprs (typeOf (last exprs))

divisionByZeroExpr =
  Application
  missing
  (Application
   missing
   (MethodReference
    missing
    (Unresolved
     (nameInUniverse "Num")
     (Identifier "Divide")
     (ProtocolConstraint missing (nameInUniverse "Num") typeInt))
    (TFn missing typeInt (TFn missing typeInt typeInt)))
   (intExpr 1)
   (TFn missing typeInt typeInt))
  (intExpr 0)
  typeInt

myPkgName = NativePackageName ["mypkg"]

emptyPkg = TypedPackage (PackageDeclaration missing (NativePackageName ["empty", "pkg"])) [] []

spec :: Spec
spec = do
  describe "validateExpr" $ do

    it "warns on discarded value in block" $
      validate (TypedPackage (PackageDeclaration missing myPkgName) [] [
            Definition missing (nameInUniverse "foo") $ canonical (block [strExpr, unitExpr])
        ])
      `shouldFailWith`
      ValueDiscarded strExpr

    it "does not warn on discarded unit value in block" $
      validate (TypedPackage (PackageDeclaration missing myPkgName) [] [
            Definition missing (nameInUniverse "foo") $ canonical (block [unitExpr, strExpr])
        ])
      `shouldSucceedWith`
      []

    it "accepts uniquely named definitions" $
      validate (TypedPackage (PackageDeclaration missing myPkgName) [] [
            Definition missing (nameInUniverse "foo") (canonical strExpr),
            Definition missing (nameInUniverse "bar") (canonical strExpr),
            Definition missing (nameInUniverse "baz") (canonical strExpr)
        ])
      `shouldSucceedWith`
      []

    it "throws an error on literal division by zero" $
      validate (TypedPackage (PackageDeclaration missing myPkgName) [] [
            Definition
            missing
            (nameInUniverse "foo")
            (canonical divisionByZeroExpr)
        ])
      `shouldFailWith`
      DivisionByZero divisionByZeroExpr

    it "throws an error on negative subscript" $
      validate (TypedPackage (PackageDeclaration missing myPkgName) [] [
            Definition
            missing
            (nameInUniverse "foo")
            (canonical $
              Subscript missing
                (Symbol missing (Identifier "s") typeIntSlice)
                (intExpr (-1))
                typeInt)
        ])
      `shouldFailWith`
      NegativeSliceIndex (intExpr (-1))

    it "throws an error on subslice from negative index" $
      validate (TypedPackage (PackageDeclaration missing myPkgName) [] [
            Definition
            missing
            (nameInUniverse "foo")
            (canonical $
              Subslice missing
                (Symbol missing (Identifier "s") typeIntSlice)
                (RangeFrom (intExpr (-1)))
                typeInt)
        ])
      `shouldFailWith`
      NegativeSliceIndex (intExpr (-1))

    it "throws an error on subslice to negative index" $
      validate (TypedPackage (PackageDeclaration missing myPkgName) [] [
            Definition
            missing
            (nameInUniverse "foo")
            (canonical $
              Subslice missing
                (Symbol missing (Identifier "s") typeIntSlice)
                (RangeTo (intExpr (-1)))
                typeInt)
        ])
      `shouldFailWith`
      NegativeSliceIndex (intExpr (-1))

    it "throws an error on subslice from higher to lower index" $
      validate (TypedPackage (PackageDeclaration missing myPkgName) [] [
            Definition
            missing
            (nameInUniverse "foo")
            (canonical $
              Subslice missing
                (Symbol missing (Identifier "s") typeIntSlice)
                (Range (intExpr 10) (intExpr 5))
                typeInt)
        ])
      `shouldFailWith`
      InvalidSubslice Missing (Range (intExpr 10) (intExpr 5))

  describe "validatePackage" $ do

    it "throws an error on unused imports" $
      validate (TypedPackage (PackageDeclaration missing myPkgName) [
          ImportedPackage (ImportReference missing ["empty", "pkg"]) (Identifier "foo") emptyPkg
        ] [])
      `shouldFailWith`
      UnusedImport Missing (NativePackageName ["empty", "pkg"]) (Identifier "foo")

    it "does not throw errors for used imports" $
      validate (TypedPackage (PackageDeclaration missing myPkgName) [
          ImportedPackage (ImportReference missing ["my", "pkg"]) (Identifier "other") emptyPkg
        ] [
            Definition
            missing
            (nameInUniverse "foo")
            (canonical
             (MemberAccess
              missing
              (Typed.PackageMemberAccess (Identifier "other") (Identifier "s"))
              typeInt))
        ])
      `shouldSucceedWith`
      []

    it "throws an error on duplicate imports" $ pending

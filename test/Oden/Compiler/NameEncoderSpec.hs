module Oden.Compiler.NameEncoderSpec where

import           Test.Hspec

import           Oden.Compiler.NameEncoder
import           Oden.Identifier
import           Oden.Metadata
import           Oden.QualifiedName
import           Oden.SourceInfo
import           Oden.Type.Polymorphic

missing :: Metadata SourceInfo
missing = Metadata Missing

con = TCon missing . nameInUniverse

spec :: Spec
spec = do
  describe "encodeTypeInstance" $ do
    it "encodes arrow" $
      encodeUnqualifiedTypeInstance (Identifier "foo") (TFn missing (con "int") (con "string")) `shouldBe` "foo_inst_int_to_string"
    it "encodes nested arrows" $
      encodeUnqualifiedTypeInstance (Identifier "foo") (TFn missing (con "bool") (TFn missing (con "int") (con "string"))) `shouldBe` "foo_inst_bool_to_int__to__string"
    it "encodes single arrow" $
      encodeUnqualifiedTypeInstance (Identifier "foo") (TNoArgFn missing (con "int")) `shouldBe` "foo_inst_to_int"
    it "encodes nested single arrows" $
      encodeUnqualifiedTypeInstance (Identifier "foo") (TNoArgFn missing (TNoArgFn missing (con "int"))) `shouldBe` "foo_inst_to_to__int"
    it "encodes variadic func" $
      encodeUnqualifiedTypeInstance (Identifier "foo") (TForeignFn missing True [con "bool", con "int"] [con "string"]) `shouldBe` "foo_inst_bool_to_int_variadic_to_string"
    it "encodes variadic func with multiple return values" $
      encodeUnqualifiedTypeInstance (Identifier "foo") (TForeignFn missing True [con "bool", con "int"] [con "string", con "int"]) `shouldBe` "foo_inst_bool_to_int_variadic_to_tupleof__string__int__"
    it "encodes slice" $
      encodeUnqualifiedTypeInstance (Identifier "foo") (TFn missing (TSlice missing (con "bool")) (TSlice missing (con "int"))) `shouldBe` "foo_inst_sliceof__bool_to_sliceof__int"

  describe "encodeMethodInstance" $
    it "encodes arrow" $
      encodeMethodInstance
      (FQN (NativePackageName ["the", "pkg"]) (Identifier "Foo"))
      (Identifier "bar")
      (TFn missing (con "int") (con "string"))
      `shouldBe`
      "the_pkg__Foo_method_bar_inst_int_to_string"

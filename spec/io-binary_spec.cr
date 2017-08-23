require "./spec_helper"

def self.bytes(*bytes)
  arr = bytes.flat_map do |byte|
    case byte
    when String
      byte.chars.map(&.ord).map(&.to_u8)
    when Char
      byte.ord.to_u8
    when Int32
      byte.to_u8
    else
      raise "can't make byte io from this"
    end
  end
  slice = Bytes.new(bytes.size)
  arr.each_with_index { |byte, idx| slice[idx] = byte }
  IO::Memory.new(slice)
end

module IO
  describe Binary do
    describe "aligned?" do
      it "returns true if byte aligned" do
        io = bytes(0b00000001)
        reader = Binary.new(io)
        reader.read_byte

        reader.aligned?.should be_true
      end

      it "returns false if not byte aligned" do
        io = bytes(0b00000001)
        reader = Binary.new(io)
        reader.read_bit

        reader.aligned?.should be_false
      end
    end

    describe "pos_bits" do
      it "returns the bit pos" do
        io = bytes(0b00000001)
        reader = Binary.new(io)
        reader.read_bit

        reader.pos_bits.should eq(1)
      end

      it "works after reading" do
        io = bytes(0b00000001, 0b11111111)
        reader = Binary.new(io)
        reader.read_byte
        reader.read_bit

        reader.pos_bits.should eq(9)
      end
    end

    describe "read_float" do
      it "can read a float" do
        io = bytes(192, 22, 57, 69)
        reader = Binary.new(io)

        reader.read_float.should be_close(2961.42.to_f32, 0.01)
      end
    end

    describe "read_bit" do
      it "reads a bit" do
        io = bytes(0b00000001)
        reader = Binary.new(io)

        reader.read_bit.should eq(1)
        7.times { reader.read_bit.should eq(0) }
      end
    end

    describe "read_bool" do
      it "reads a bool" do
        io = bytes(0b00000001)
        reader = Binary.new(io)

        reader.read_bool.should eq(true)
        7.times { reader.read_bool.should eq(false) }
      end
    end

    describe "read_uint64_be" do
      it "reads a 64bit with big endian byte order" do
        io = bytes(1, 16, 0, 1, 2, 66, 188, 64)
        reader = Binary.new(io)

        reader.read_uint64_be.should eq(76561197998193728)
      end
    end

    describe "read" do
      it "can read by size" do
        io = bytes(0xFF, 0x01)
        reader = Binary.new(io)

        reader.read(1).should eq(Bytes.new(1, 0xFF.to_u8))
      end

      it "reads bytes" do
        io = bytes(0xFF, 0x01)
        reader = Binary.new(io)

        bytes = Bytes.new(1)
        reader.read(bytes)
        bytes.should eq(Bytes.new(1, 0xFF.to_u8))
      end

      it "works when not byte aligned" do
        io = bytes(0b11111110, 0b000000001)
        reader = Binary.new(io)
        reader.read_bit

        bytes = Bytes.new(1)
        reader.read(bytes)
        bytes.should eq(Bytes.new(1, 0xFF.to_u8))
      end
    end

    describe "read_int32" do
      it "can read int32" do
        io = bytes(0xFF, 0xFF, 0xFF, 0xFF)
        reader = Binary.new(io)

        reader.read_int32.should eq(-1)
      end
    end

    describe "read_int16" do
      it "can read int16" do
        io = bytes(244, 0)
        reader = Binary.new(io)

        reader.read_int16.should eq(244)
      end
    end

    describe "read_string" do
      it "can read strings by size" do
        io = bytes("H", "i", "!")

        reader = Binary.new(io)
        reader.read_string(3).should eq("Hi!")
      end

      it "can read zero terminated strings" do
        io = bytes("H", "e", "y", "!", 0x00)

        reader = Binary.new(io)
        reader.read_string.should eq("Hey!")
      end
    end
  end
end

require "./io-binary/*"

# Binary IO implementation allowing bit level reading
module IO
  class Binary
    include IO

    # :nodoc:
    private class Buffer
      getter pos

      @pos = 0
      @bytes = Bytes.new(256)

      def initialize(@io : IO)
        refresh
      end

      # Returns the next byte in the internal buffer. Refreshing the buffer if
      # required.
      def next_byte : UInt8
        refresh if @pos == @bytes.size
        @pos += 1
        @bytes[@pos - 1]
      end

      private def refresh
        @pos = 0
        @io.read(@bytes)
      end
    end

    # Current location, in bytes.
    getter pos

    @bit_count : UInt32 = 0.to_u32
    @bit_val : UInt64 = 0.to_u64
    @pos = 0

    def initialize(io : IO)
      @buffer = Buffer.new(io)
    end

    def initialize(bytes : Bytes)
      @buffer = Buffer.new(IO::Memory.new(bytes))
    end

    def initialize(slice : Slice)
      @buffer = Buffer.new(IO::Memory.new(slice))
    end

    # Not implemented
    def write(slice : Bytes)
      raise "#{self.class.name} does not support writing."
    end

    # Reads up to the size of *slice*.
    def read(slice : Bytes)
      read_impl(slice)
    end

    # Reads *size* number of bytes.
    def read(size : Int32) : Bytes
      bytes = Bytes.new(size)
      read(bytes)
      bytes
    end

    # Read *size* number of bits.
    def read_bits(size : Int32) : UInt32
      read_bits_impl(size)
    end

    # Read a single bit.
    def read_bit : UInt32
      read_bits(1)
    end

    # Read a `Bool`.
    def read_bool : Bool
      read_bit == 1
    end

    # Read an `UInt64` in big endian format.
    def read_uint64_be : UInt64
      read_bytes(UInt64, IO::ByteFormat::BigEndian)
    end

    # Read an `UInt64`.
    def read_uint64 : UInt64
      read_bytes(UInt64, IO::ByteFormat::LittleEndian)
    end

    # Read a `Int64`.
    def read_int64 : Int64
      read_bytes(Int64, IO::ByteFormat::LittleEndian)
    end

    # Read an `Int32`.
    def read_int32 : Int32
      read_bytes(Int32, IO::ByteFormat::LittleEndian)
    end

    # Read an `Int32` in big endian byte format.
    def read_int32_be : Int32
      read_bytes(Int32, IO::ByteFormat::BigEndian)
    end

    # Read a `Int16`.
    def read_int16 : Int16
      read_bytes(Int16, IO::ByteFormat::LittleEndian)
    end

    # Reads a `Float32`.
    def read_float : Float32
      read_bytes(Float32, IO::ByteFormat::LittleEndian)
    end

    # Read a `String` of the given *size*.
    def read_string(size : Int32) : String
      slice = Bytes.new(size)
      read(slice)
      String.new(slice)
    end

    # Read a `String` until first null character.
    def read_string : String
      String.build do |str|
        loop do
          byte = read_byte
          break if byte == 0
          str << byte.not_nil!.chr
        end
      end
    end

    # Return the position in the `IO` in bits.
    def pos_bits
      ((@pos - 1) << 3) + (8 - @bit_count)
    end

    # Returns `true` if byte aligned, `false` otherwise.
    def aligned?
      pos_bits % 8 == 0
    end

    # :nodoc:
    private def read_impl(slice)
      if @bit_count == 0
        slice.size.times { |i| slice[i] = next_byte }
      else
        slice.size.times { |i| slice[i] = read_bits(8).to_u8 }
      end
      slice.size
    end

    # :nodoc:
    private def read_bits_impl(size : Int32) : UInt32
      raise "out of bounds" if size > 64

      while size > @bit_count
        @bit_val |= next_byte.to_u64 << @bit_count
        @bit_count += 8
      end

      result = (@bit_val & ((1 << size) - 1))
      @bit_val >>= size
      @bit_count -= size
      result.to_u32
    end

    private def next_byte : UInt8
      @buffer.next_byte.tap { @pos += 1 }
    end
  end
end

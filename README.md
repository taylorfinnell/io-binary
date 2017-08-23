# io-binary

An IO implementation that supports bit level reading.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  io-binary:
    github: taylorfinnell/io-binary
```

## Usage

`require "io-binary"`


```crystal
io = IO::Binary.new(Bytes.new(1, 3.to_u8)) # single byte of value 3

io.read_bit # => 1
io.read_bit # => 1
io.read_bit # => 0
```

## Limits

Does not implement `IO#write`.



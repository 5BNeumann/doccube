# Doccube
A documentation tool made in nim which produces output in sugarcube for some reason.

## Build

You will need:
* nimble
* nim (>= 2.10.0 but >=2.0.0 should work)

```
nimble build
```

## Use

### Documenting

You need to write comments that respect a pretty strict format.

Some fields are used to document functions, types and sanity:
```nim
# @doc <Thing you are documenting>
# @kind <func, type or san to document a function, a type or a developer's sanity>
# @desc <The description>
```
`@doc` and `@kind` are mandatory, must be at the start of a doc comment in this order.

While others are limited to a single type.

Functions:
```nim
# @param <param name>: <param type, if custom, should probably be wrapped in [[]]> <optional description starting with ", ">
# @returns <return type, if custom, should probably be wrapped in [[]]>
```

Types:
```nim
# @field <field name>: <field type, if custom, should probably be wrapped in [[]]> <optional description starting with ", ">
```

Sanity:
```nim
# @level <8 bit signed integer>
```

Do note that `#` is used here since I mostly used this tool with nim (yes, I know `nim doc` exists, no, I don't care, I'm creating this for fun).

### Running

You need to create a configuration file `doccube_config.txt` at the root of your project.

In it, you need to specify source dirs:
```
source_dir:src/
```
It can be used multiple times.

The project's name:
```
name:Doccube
```
And the projects description:
```
desc:A small documentation tool written in nim that outputs sugarcube
```
You may also enable the sugarcube output:
```
sugarcube_out:true
```
At some point in time, there will probably be tex output through:
```
tex_out:true
```
Additionally, you need to create a specification file for each language you want to document.

It contains two mandatory keys:
```
file_extension:.nim
starter_comment:#
```
Both are pretty explicit.

`file_extension` MUST start by a `.` to  work properly.

You can then run `./doccube <specification files>`.

E.g:
```
./doccube nimconfig
```

You then need to build the doc using `tweego`:
```
tweego doc/sugarcube -o documentation.html
open documentation.html
```

## Roadmap

Adding tex output.

Allowing custom CSS for the sugarcube output.

Making comment detection support multiline comments.

# Doccube
A documentation tool made in nim which produces output in sugarcube for some reason.

## Build

You will need:
* nimble
* nim

```
nimble build
```

## Use

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

You then need to build the doc using `tweego`:
```
tweego doc/sugarcube -o documentation.html
open documentation.html
```

## Roadmap

Making comment detection configurable (and actually decent).
Adding tex output.
Making the sugarcube output look better.
Allowing custom CSS for the sugarcube output.

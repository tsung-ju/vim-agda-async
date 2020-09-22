# vim-agda-async

Agda plugin for Vim 8

work in progress

Based on [derekelkins/agda-vim](https://github.com/derekelkins/agda-vim)

## Mappings

Commands working with types can be prefixed with `u` to compute
type without further normalisation and with `uu` to compute
normalised types.
For example, `<LocalLeader>um` `<LocalLeader>uum`

| Binding                | Local | Global | Prefix   | Description |
| ---------------------- | ----- | ------ | -------- | ----------- |
| \<LocalLeader>l        |       | v      |          | Save the file and Load |
| \<LocalLeader>xc       |       | v      |          | Save the file and Compile |
| \<LocalLeader>xr       |       | v      |          | Kill and restart Agda |
| \<LocalLeader>xa       |       | v      |          | Abort a command |
| \<LocalLeader>xh       |       | v      |          | Toggle display of hidden arguments |
| \<LocalLeader>=        |       | v      |          | Show constraints |
| \<LocalLeader>s        | v     | v      |          | Solve constraints |
| \<LocalLeader>?        |       | v      |          | Show goals |
| \<LocalLeader>f        |       | v      |          | Next goal |
| \<LocalLeader>b        |       | v      |          | Previous goal |
| \]g                    |       | v      |          | Next goal |
| \[g                    |       | v      |          | Previous goal |
| \<LocalLeader>\<Space> | v     |        | `u`      | Give |
| \<LocalLeader>m        | v     |        | `u` `uu` | Elaborate and Give |
| \<LocalLeader>r        | v     |        |          | Refine |
| \<LocalLeader>a        | v     | v      |          | Auto |
| \<LocalLeader>c        | v     |        |          | Case |
| \<LocalLeader>t        | v     |        | `u` `uu` | Goal type |
| \<LocalLeader>e        | v     |        | `u` `uu` | Context environment |
| \<LocalLeader>h        | v     |        | `u` `uu` | Helper function type |
| \<LocalLeader>d        | v     | v      | `u` `uu` | Infer deduce type |
| \<LocalLeader>w        | v     | v      |          | Explain why a particular name is in scope |
| \<LocalLeader>,        | v     |        | `u` `uu` | Goal type and context |
| \<LocalLeader>.        | v     |        | `u` `uu` | Goal type, context and inferred type |
| \<LocalLeader>;        | v     |        | `u` `uu` | Goal type, context and checked type |
| \<LocalLeader>z        | v     | v      | `u` `uu` | Search About |
| \<LocalLeader>o        | v     | v      | `u` `uu` | Module contents |
| \<LocalLeader>n        | v     | v      | `u`      | Evaluate term to normal form |

## Unicode input method

![agda-input](https://user-images.githubusercontent.com/16625236/62801703-d708f680-bad5-11e9-928f-65b449902709.gif)

This feature can be disabled by setting `g:agda_input_enable` to `0`.

The default mappings are the same as in Emacs.

Additional mappings can be specified via `g:agda_input_mappings`, e.g.
```vim
let g:agda_input_mappings = { '++': '⧺' , ';': ['︔', '؛'] }
```

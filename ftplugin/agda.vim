" Copyright (C) 2019  ray851107
"
" This file is part of vim-agda-async.
"
" vim-agda-async is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" vim-agda-async is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with vim-agda-async.  If not, see <https://www.gnu.org/licenses/>.

call agda#input#activate()

function s:map(key, cmd, arg='')
  execute 'nnoremap <buffer><silent> <localleader>' . a:key . ' :call agda#' . a:cmd . '(' . a:arg . ')<cr>'
endfunction

function s:map_u(key, cmd, options)
  for l:count in range(len(a:options))
    let l:key = repeat('u', l:count) . a:key
    call s:map(l:key, a:cmd, string(a:options[l:count]))
  endfor
endfunction

function s:map_normalise(key, cmd)
  call s:map_u(a:key, a:cmd, ['Simplified', 'Instantiated', 'Normalised'])
endfunction

call s:map('l', 'load')
call s:map('xc', 'compile')
call s:map('xr', 'restart')
call s:map('xa', 'abort')
call s:map('xh', 'toggle_implicit_args')
call s:map('=', 'constraints')
call s:map('?', 'metas')
call s:map('f', 'goal#go_next()')
call s:map('b', 'goal#go_prev()')

call s:map_u('<space>', 'give', ['WithoutForce', 'WithForce'])
call s:map_normalise('m', 'elaborate_give')
call s:map_u('r', 'refine_or_intro', ['False', 'True'])
call s:map('a', 'auto_maybe_all')
call s:map('c', 'make_case')
call s:map_normalise('t', 'goal_type')
call s:map_normalise('e', 'context')
call s:map_normalise('h', 'helper_function')
call s:map_normalise('d', 'infer_maybe_toplevel')
call s:map('w', 'why_in_scope_maybe_toplevel')
call s:map_normalise(',', 'goal_type_context')
call s:map_normalise('.', 'goal_type_context_infer')
call s:map_normalise(';', 'goal_type_context_check')
call s:map_normalise('z', 'search_about_toplevel')
call s:map_normalise('o', 'show_module_contents_maybe_toplevel')
call s:map_u('n', 'compute_maybe_toplevel', ['DefaultCompute', 'IgnoreAbstract'])

nnoremap <buffer><silent> ]g :call agda#goal#go_next()<cr>
nnoremap <buffer><silent> [g :call agda#goal#go_prev()<cr>

call agda#load()

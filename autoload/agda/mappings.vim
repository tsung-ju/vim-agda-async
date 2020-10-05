" Copyright (C) 2020  ray851107
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

function agda#mappings#init()
  call s:init_plug_mappings()

  call s:map('l', 'load')
  call s:map('xc', 'compile')
  call s:map('xr', 'restart')
  call s:map('xa', 'abort')
  call s:map('xh', 'toggle-implicit-args')
  call s:map('=', 'constraints')
  call s:map('?', 'metas')
  call s:map('b', 'previous-goal')
  call s:map('f', 'next-goal')

  call s:map_u('<Space>', ['give', 'give-with-force'])
  call s:map_normalise('m', 'elaborate-give')
  call s:map_u('r', ['refine', 'refine-pmlambda'])
  call s:map('a', 'auto')
  call s:map('c', 'make-case')
  call s:map_normalise('t', 'goal-type')
  call s:map_normalise('e', 'context')
  call s:map_normalise('h', 'helper-function')
  call s:map_normalise('d', 'infer')
  call s:map('w', 'why-in-scope-maybe')
  call s:map_normalise(',', 'goal-type-context')
  call s:map_normalise('.', 'goal-type-context-infer')
  call s:map_normalise(';', 'goal-type-context-check')
  call s:map_normalise('z', 'search-about-toplevel')
  call s:map_normalise('o', 'show-module-contents')
  call s:map_u('n', ['compute', 'compute-ignore-abstract'])

  if !hasmapto('<Plug>(agda-goto-definition)', 'n')
    nmap <buffer> gd <Plug>(agda-goto-definition)
  endif
endfunction

function s:init_plug_mappings()
  nnoremap <buffer><silent> <Plug>(agda-goto-definition) :<C-u>call agda#definition#go(bufnr('%'))<CR>

  nnoremap <buffer><silent> <Plug>(agda-load) :<C-u>call agda#load()<CR>
  nnoremap <buffer><silent> <Plug>(agda-compile) :<C-u>call agda#compile()<CR>
  nnoremap <buffer><silent> <Plug>(agda-restart) :<C-u>call agda#restart()<CR>
  nnoremap <buffer><silent> <Plug>(agda-abort) :<C-u>call agda#abort()<CR>
  nnoremap <buffer><silent> <Plug>(agda-toggle-implicit-args) :<C-u>call agda#toggle_implicit_args()<CR>
  nnoremap <buffer><silent> <Plug>(agda-constraints) :<C-u>call agda#constraints()<CR>
  nnoremap <buffer><silent> <Plug>(agda-metas) :<C-u>call agda#metas()<CR>
  nnoremap <buffer><silent> <Plug>(agda-previous-goal) :<C-u>call agda#goal#go_prev()<CR>
  nnoremap <buffer><silent> <Plug>(agda-next-goal) :<C-u>call agda#goal#go_next()<CR>

  nnoremap <buffer><silent> <Plug>(agda-give) :<C-u>call agda#give('WithoutForce')<CR>
  nnoremap <buffer><silent> <Plug>(agda-give-with-force) :<C-u>call agda#give('WithForce')<CR>
  nnoremap <buffer><silent> <Plug>(agda-elaborate-give-simplified) :<C-u>call agda#elaborate_give('Simplified')<CR>
  nnoremap <buffer><silent> <Plug>(agda-elaborate-give-instantiated) :<C-u>call agda#elaborate_give('Instantiated')<CR>
  nnoremap <buffer><silent> <Plug>(agda-elaborate-give-normalised) :<C-u>call agda#elaborate_give('Normalised')<CR>
  nnoremap <buffer><silent> <Plug>(agda-refine) :<C-u>call agda#refine_or_intro('False')<CR>
  nnoremap <buffer><silent> <Plug>(agda-refine-pmlambda) :<C-u>call agda#refine_or_intro('True')<CR>
  nnoremap <buffer><silent> <Plug>(agda-auto) :<C-u>call agda#auto_maybe_all()<CR>
  nnoremap <buffer><silent> <Plug>(agda-make-case) :<C-u>call agda#make_case()<CR>
  nnoremap <buffer><silent> <Plug>(agda-goal-type-simplified) :<C-u>call agda#goal_type('Simplified')<CR>
  nnoremap <buffer><silent> <Plug>(agda-goal-type-instantiated) :<C-u>call agda#goal_type('Instantiated')<CR>
  nnoremap <buffer><silent> <Plug>(agda-goal-type-normalised) :<C-u>call agda#goal_type('Normalised')<CR>
  nnoremap <buffer><silent> <Plug>(agda-context-simplified) :<C-u>call agda#context('Simplified')<CR>
  nnoremap <buffer><silent> <Plug>(agda-context-instantiated) :<C-u>call agda#context('Instantiated')<CR>
  nnoremap <buffer><silent> <Plug>(agda-context-normalised) :<C-u>call agda#context('Normalised')<CR>
  nnoremap <buffer><silent> <Plug>(agda-helper-function-simplified) :<C-u>call agda#helper_function('Simplified')<CR>
  nnoremap <buffer><silent> <Plug>(agda-helper-function-instantiated) :<C-u>call agda#helper_function('Instantiated')<CR>
  nnoremap <buffer><silent> <Plug>(agda-helper-function-normalised) :<C-u>call agda#helper_function('Normalised')<CR>
  nnoremap <buffer><silent> <Plug>(agda-infer-simplified) :<C-u>call agda#infer_maybe_toplevel('Simplified')<CR>
  nnoremap <buffer><silent> <Plug>(agda-infer-instantiated) :<C-u>call agda#infer_maybe_toplevel('Instantiated')<CR>
  nnoremap <buffer><silent> <Plug>(agda-infer-normalised) :<C-u>call agda#infer_maybe_toplevel('Normalised')<CR>
  nnoremap <buffer><silent> <Plug>(agda-why-in-scope) :<C-u>call agda#why_in_scope_maybe_toplevel()<CR>
  nnoremap <buffer><silent> <Plug>(agda-goal-type-context-simplified) :<C-u>call agda#goal_type_context('Simplified')<CR>
  nnoremap <buffer><silent> <Plug>(agda-goal-type-context-instantiated) :<C-u>call agda#goal_type_context('Instantiated')<CR>
  nnoremap <buffer><silent> <Plug>(agda-goal-type-context-normalised) :<C-u>call agda#goal_type_context('Normalised')<CR>
  nnoremap <buffer><silent> <Plug>(agda-goal-type-context-infer-simplified) :<C-u>call agda#goal_type_context_infer('Simplified')<CR>
  nnoremap <buffer><silent> <Plug>(agda-goal-type-context-infer-instantiated) :<C-u>call agda#goal_type_context_infer('Instantiated')<CR>
  nnoremap <buffer><silent> <Plug>(agda-goal-type-context-infer-normalised) :<C-u>call agda#goal_type_context_infer('Normalised')<CR>
  nnoremap <buffer><silent> <Plug>(agda-goal-type-context-check-simplified) :<C-u>call agda#goal_type_context_check('Simplified')<CR>
  nnoremap <buffer><silent> <Plug>(agda-goal-type-context-check-instantiated) :<C-u>call agda#goal_type_context_check('Instantiated')<CR>
  nnoremap <buffer><silent> <Plug>(agda-goal-type-context-check-normalised) :<C-u>call agda#goal_type_context_check('Normalised')<CR>
  nnoremap <buffer><silent> <Plug>(agda-search-about-simplified) :<C-u>call agda#search_about_toplevel('Simplified')<CR>
  nnoremap <buffer><silent> <Plug>(agda-search-about-instantiated) :<C-u>call agda#search_about_toplevel('Instantiated')<CR>
  nnoremap <buffer><silent> <Plug>(agda-search-about-normalised) :<C-u>call agda#search_about_toplevel('Normalised')<CR>
  nnoremap <buffer><silent> <Plug>(agda-show-module-contents-simplified) :<C-u>call agda#show_module_contents_maybe_toplevel('Simplified')<CR>
  nnoremap <buffer><silent> <Plug>(agda-show-module-contents-instantiated) :<C-u>call agda#show_module_contents_maybe_toplevel('Instantiated')<CR>
  nnoremap <buffer><silent> <Plug>(agda-show-module-contents-normalised) :<C-u>call agda#show_module_contents_maybe_toplevel('Normalised')<CR>
  nnoremap <buffer><silent> <Plug>(agda-compute) :<C-u>call agda#compute_maybe_toplevel('DefaultCompute')<CR>
  nnoremap <buffer><silent> <Plug>(agda-compute-ignore-abstract) :<C-u>call agda#compute_maybe_toplevel('IgnoreAbstract')<CR>
endfunction

function s:map(key, cmd)
  let l:target = '<Plug>(agda-' . a:cmd . ')'
  if !hasmapto(l:target, 'n')
    execute 'nmap <buffer> <LocalLeader>' . a:key . ' ' . l:target
  endif
endfunction

function s:map_u(key, cmds)
  for l:count in range(len(a:cmds))
    call s:map(repeat('u', l:count) . a:key, a:cmds[l:count])
  endfor
endfunction

function s:map_normalise(key, cmd)
  call s:map_u(a:key, [a:cmd . '-simplified', a:cmd . '-instantiated', a:cmd . '-normalised'])
endfunction

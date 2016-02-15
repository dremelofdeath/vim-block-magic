" blockmagic.vim - Make Vim's handling of block objects a little more clever.
" Maintainer:  Zachary Murray (dremelofdeath@gmail.com)
" Version:     1.0

if exists('g:loaded_zcm_blockmagic') || &cp
  finish
endif

let g:loaded_zcm_blockmagic = 1

function! s:GetVisualSelection()
  " Why is this not a built-in VimScript function?
  " Stolen from here: http://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  " this is a bug fix from me: when you first start vim, there is no selection
  " and this logic fails because col1 and col2 are both 0 (only true on start)
  if col1 == 0 || col2 == 0
    return ""
  endif
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfunction

" NOTE: There are two known issues when using this implementation of block
" matching in visual and operator-pending modes! These issues are deviations
" (albeit minor ones) from Vim's default behavior when using these mappings.
"
"   1. Trying to select a visual block using 'vab' or the like when there is
"      none on the current line drops you to normal mode
"
"      New behavior in this case: Return to normal mode
"      Vim's behavior in this case: Stay in visual mode
"
"   2. Any command that accepts a motion in operator-pending mode and would, on
"      success, drop you into insert mode (such as normal mode c) drops you into
"      insert mode regardless of if there is a valid selection on the current
"      line or not
"
"      New behavior in this case: Drop into insert mode at cursor position
"      Vim's behavior in this case: Cancel operation and return to normal mode

function! s:PerformBlockMatchingMagic_Visual(left_char, right_char)
  exe "silent! normal! va".a:left_char."\<Esc>"
  let l:selection = s:GetVisualSelection()
  exe "silent! normal! \<Esc>va".a:left_char
  if strlen(l:selection) <= 1
    let [lnum, lcol] = getpos('.')[1:2]
    exe "silent! normal! \<Esc>f".a:left_char
    let l:char = getline('.')[col('.')-1]
    if char == a:left_char
      silent! normal! %
      let l:char = getline('.')[col('.')-1]
      if l:char == a:right_char
        silent! normal! %v%
      else
        silent! call cursor(lnum, lcol)
      endif
    endif
  endif
endfunction

function! s:PerformInnerBlockMatchingMagic_Visual(left_char, right_char)
  call <SID>PerformBlockMatchingMagic_Visual(a:left_char, a:right_char)
  exe "silent! normal! \<Esc>"
  let l:char = getline('.')[col('.')-1]
  if char == a:right_char
    silent! normal! %lvh%h
  endif
endfunction

" replaces a( motion with a way better version
vnoremap <silent> <Plug>BlockMagic_v_a( :<C-U>call <SID>PerformBlockMatchingMagic_Visual('(', ')')<CR>
vnoremap <silent> <Plug>BlockMagic_v_a) :<C-U>call <SID>PerformBlockMatchingMagic_Visual('(', ')')<CR>
vnoremap <silent> <Plug>BlockMagic_v_ab :<C-U>call <SID>PerformBlockMatchingMagic_Visual('(', ')')<CR>
onoremap <silent> <Plug>BlockMagic_o_a( :<C-U>normal vab<CR>
onoremap <silent> <Plug>BlockMagic_o_a) :<C-U>normal vab<CR>
onoremap <silent> <Plug>BlockMagic_o_ab :<C-U>normal vab<CR>
" replaces i( motion with a way better version
vnoremap <silent> <Plug>BlockMagic_v_i( :<C-U>call <SID>PerformInnerBlockMatchingMagic_Visual('(', ')')<CR>
vnoremap <silent> <Plug>BlockMagic_v_i) :<C-U>call <SID>PerformInnerBlockMatchingMagic_Visual('(', ')')<CR>
vnoremap <silent> <Plug>BlockMagic_v_ib :<C-U>call <SID>PerformInnerBlockMatchingMagic_Visual('(', ')')<CR>
onoremap <silent> <Plug>BlockMagic_o_i( :<C-U>normal vib<CR>
onoremap <silent> <Plug>BlockMagic_o_i) :<C-U>normal vib<CR>
onoremap <silent> <Plug>BlockMagic_o_ib :<C-U>normal vib<CR>
" same as above for a[ a] a{ a} i[ i] i{ i} motions
vnoremap <silent> <Plug>BlockMagic_v_a[ :<C-U>call <SID>PerformBlockMatchingMagic_Visual('[', ']')<CR>
vnoremap <silent> <Plug>BlockMagic_v_a] :<C-U>call <SID>PerformBlockMatchingMagic_Visual('[', ']')<CR>
onoremap <silent> <Plug>BlockMagic_o_a[ :<C-U>normal va[<CR>
onoremap <silent> <Plug>BlockMagic_o_a] :<C-U>normal va]<CR>
vnoremap <silent> <Plug>BlockMagic_v_i[ :<C-U>call <SID>PerformInnerBlockMatchingMagic_Visual('[', ']')<CR>
vnoremap <silent> <Plug>BlockMagic_v_i] :<C-U>call <SID>PerformInnerBlockMatchingMagic_Visual('[', ']')<CR>
onoremap <silent> <Plug>BlockMagic_o_i[ :<C-U>normal vi[<CR>
onoremap <silent> <Plug>BlockMagic_o_i] :<C-U>normal vi]<CR>
vnoremap <silent> <Plug>BlockMagic_v_a{ :<C-U>call <SID>PerformBlockMatchingMagic_Visual('{', '}')<CR>
vnoremap <silent> <Plug>BlockMagic_v_a} :<C-U>call <SID>PerformBlockMatchingMagic_Visual('{', '}')<CR>
vnoremap <silent> <Plug>BlockMagic_v_aB :<C-U>call <SID>PerformBlockMatchingMagic_Visual('{', '}')<CR>
onoremap <silent> <Plug>BlockMagic_o_a{ :<C-U>normal va{<CR>
onoremap <silent> <Plug>BlockMagic_o_a} :<C-U>normal va}<CR>
onoremap <silent> <Plug>BlockMagic_o_aB :<C-U>normal vaB<CR>
vnoremap <silent> <Plug>BlockMagic_v_i{ :<C-U>call <SID>PerformInnerBlockMatchingMagic_Visual('{', '}')<CR>
vnoremap <silent> <Plug>BlockMagic_v_i} :<C-U>call <SID>PerformInnerBlockMatchingMagic_Visual('{', '}')<CR>
vnoremap <silent> <Plug>BlockMagic_v_iB :<C-U>call <SID>PerformInnerBlockMatchingMagic_Visual('{', '}')<CR>
onoremap <silent> <Plug>BlockMagic_o_i{ :<C-U>normal vi{<CR>
onoremap <silent> <Plug>BlockMagic_o_i} :<C-U>normal vi}<CR>
onoremap <silent> <Plug>BlockMagic_o_iB :<C-U>normal viB<CR>

if !exists('g:BlockMagic_MapKeys')
  let g:BlockMagic_MapKeys = 1
endif

if g:BlockMagic_MapKeys
  vmap a( <Plug>BlockMagic_v_a(
  vmap a) <Plug>BlockMagic_v_a)
  vmap ab <Plug>BlockMagic_v_ab
  omap a( <Plug>BlockMagic_o_a(
  omap a) <Plug>BlockMagic_o_a)
  omap ab <Plug>BlockMagic_o_ab
  vmap i( <Plug>BlockMagic_v_i(
  vmap i) <Plug>BlockMagic_v_i)
  vmap ib <Plug>BlockMagic_v_ib
  omap i( <Plug>BlockMagic_o_i(
  omap i) <Plug>BlockMagic_o_i)
  omap ib <Plug>BlockMagic_o_ib
  vmap a[ <Plug>BlockMagic_v_a[
  vmap a] <Plug>BlockMagic_v_a]
  omap a[ <Plug>BlockMagic_o_a[
  omap a] <Plug>BlockMagic_o_a]
  vmap i[ <Plug>BlockMagic_v_i[
  vmap i] <Plug>BlockMagic_v_i]
  omap i[ <Plug>BlockMagic_o_i[
  omap i] <Plug>BlockMagic_o_i]
  vmap a{ <Plug>BlockMagic_v_a{
  vmap a} <Plug>BlockMagic_v_a}
  vmap aB <Plug>BlockMagic_v_aB
  omap a{ <Plug>BlockMagic_o_a{
  omap a} <Plug>BlockMagic_o_a}
  omap aB <Plug>BlockMagic_o_aB
  vmap i{ <Plug>BlockMagic_v_i{
  vmap i} <Plug>BlockMagic_v_i}
  vmap iB <Plug>BlockMagic_v_iB
  omap i{ <Plug>BlockMagic_o_i{
  omap i} <Plug>BlockMagic_o_i}
  omap iB <Plug>BlockMagic_o_iB
endif


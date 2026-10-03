import re
p = r'c:\Hamden\Sistemas\Backend\delphi\delphi7\FastFile\Components\FileReadThread-2\Src\Biblioteca.pas'
with open(p, 'rb') as f:
    d = f.read()
d2, n = re.subn(
    rb"VK_TAB: ShowMessage\('[^']*'\)",
    b"VK_TAB: ShowMessage('Attention: use the ENTER key only, not TAB.')",
    d,
    count=1,
)
if n:
    with open(p, 'wb') as f:
        f.write(d2)
    print('fixed VK_TAB message')
else:
    print('pattern not found')

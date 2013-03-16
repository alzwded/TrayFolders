{
    This file is part of TrayFolders.

    TrayFolders is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation version 3.0.

    TrayFolders is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with TrayFolders.  If not, see <http://www.gnu.org/licenses/>.
}

unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShellApi, ShlObj;

type
  TForm2 = class(TForm)
    Edit1: TEdit;
    btnBrowse: TButton;
    btnOkay: TButton;
    btnCancel: TButton;
    procedure btnBrowseClick(Sender: TObject);
    procedure btnOkayClick(Sender: TObject);
  private
    { Private declarations }
    //theSelf: TForm1^;
    function browseDialog
      (const Title: string; const Flag: integer): string;

  public
    { Public declarations }
    {
    dataFileLocation: UnicodeString;
    folders: array of^ UnicodeString;
    foldersNumber: integer;}
    result: UnicodeString;
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

function browseForFolderCallback
  (Wnd: HWND; uMsg: UINT; lParam, lpData: LPARAM):
  integer stdcall;
var
  wa, rect : TRect;
  dialogPT : TPoint;
begin
  //center in work area
  if uMsg = BFFM_INITIALIZED then
  begin
    wa := Screen.WorkAreaRect;
    GetWindowRect(Wnd, Rect);
    dialogPT.X := ((wa.Right-wa.Left) div 2) -
                  ((rect.Right-rect.Left) div 2);
    dialogPT.Y := ((wa.Bottom-wa.Top) div 2) -
                  ((rect.Bottom-rect.Top) div 2);
    MoveWindow(Wnd,
               dialogPT.X,
               dialogPT.Y,
               Rect.Right - Rect.Left,
               Rect.Bottom - Rect.Top,
               True);
  end;

  Result := 0;
end;

function TForm2.browseDialog
 (const Title: string; const Flag: integer): string;
var
  lpItemID : PItemIDList;
  BrowseInfo : TBrowseInfo;
  DisplayName : array[0..MAX_PATH] of char;
  TempPath : array[0..MAX_PATH] of char;
begin
  Result:='';
  FillChar(BrowseInfo, sizeof(TBrowseInfo), #0);
  with BrowseInfo do begin
    hwndOwner := Application.Handle;
    pszDisplayName := @DisplayName;
    lpszTitle := PChar(Title);
    ulFlags := Flag;
    lpfn := browseForFolderCallback;
  end;
  lpItemID := SHBrowseForFolder(BrowseInfo);
  if lpItemId <> nil then begin
    SHGetPathFromIDList(lpItemID, TempPath);
    Result := TempPath;
    GlobalFreePtr(lpItemID);
  end;
end;

procedure TForm2.btnBrowseClick(Sender: TObject);
var
  folderName: string;
begin
{
  OpenDialog1.Filter := '';
  OpenDialog1.Execute(Self.Handle);}
{
  GetVersionExW(sysInfo);

  if sysInfo.dwMajorVersion >= 6 then
  begin
    fopen := TFileOpenDialog.Create(Self);
    fopen.Options := fopen.Options + [fdoPickFolders];
    if fopen.Execute then
    begin
      //MessageDlg(fopen.FileName, mtInformation, [mbOK], 0);
      Self.Edit1.Text := fopen.FileName;
    end;
    fopen.Free;
  end
  else
  begin

  end;}
  folderName := browseDialog('Choose a folder', BIF_RETURNONLYFSDIRS);
  Self.Edit1.Text := folderName;
end;

procedure TForm2.btnOkayClick(Sender: TObject);
var
  f: TextFile;
  i: integer;
begin
  result := Edit1.Text;
end;

end.

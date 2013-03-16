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

{todo: add show/hide folders feature}
unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ExtCtrls, ComCtrls, StdCtrls, FileCtrl, ShellApi, Unit2,
  ShlObj, ActiveX, ComObj;

  {for shortcut ShlObj, ActiveX, ComObj;}
  {for win32 api Windows}
  {for :-?? FileCtrl}
  {for shellCalls ShellApi}

const
  //the message for the extra overriden-control-menu item
  aboutMenuItem = WM_USER + 2;
  toggleMenuItem = WM_USER + 1;
  Version = '1.1';

type
  TForm1 = class(TForm)
    TrayIcon1: TTrayIcon;
    TrayMenu: TPopupMenu;
    Addnewfolder1: TMenuItem;
    N2: TMenuItem;
    Exit1: TMenuItem;
    StatusBar1: TStatusBar;
    ChangeMenu: TPopupMenu;
    N1: TMenuItem;
    DeleteCurrent1: TMenuItem;
    N3: TMenuItem;
    FileListBox1: TFileListBox;
    ElementMenu: TPopupMenu;
    Open1: TMenuItem;
    N4: TMenuItem;
    Delete1: TMenuItem;
    About1: TMenuItem;
    N5: TMenuItem;
    OpeninFolder1: TMenuItem;
    procedure Exit1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FileListBox1DblClick(Sender: TObject);
    procedure Addnewfolder1Click(Sender: TObject);
    procedure DeleteCurrent1Click(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure FileListBox1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure FileListBox1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure Open1Click(Sender: TObject);
    procedure Delete1Click(Sender: TObject);
    procedure OpeninFolder1Click(Sender: TObject);
    procedure FileListBox1KeyPress(Sender: TObject; var Key: Char);
    procedure About1Click(Sender: TObject);
    procedure FileListBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    dataFileLocation: UnicodeString;
    folders: array of UnicodeString;
    foldersLength: integer;
    currentMenuItem: integer;
    changeFolder: boolean;
    toggle: boolean;

    //for drag'n'drop purposes
    FileBox1WindowProc: TWndMethod;
    procedure FileBox1NewWindowProc(var Msg: TMessage);
    procedure FileBOx1AfterDrop(var Msg: TWMDROPFILES);

    procedure CreateLink(source: PWideChar; where: PWideChar);

    procedure WriteNewFolder(dir: UnicodeString);
    procedure LoadFolder(which: integer);
    procedure LoadDataInit;
    function GetFolder(s: UnicodeString): UnicodeString;
    procedure LoadData(s: UnicodeString);
    procedure FolderItemClick(Sender: TObject);
    procedure doOpen;
    procedure doAbout;
    procedure doToggle;

    //trap WMSYSCOMMAND for overriding control menu
    procedure WMSysCommand(var Msg: TWMSysCommand);
      message WM_SYSCOMMAND;

  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.About1Click(Sender: TObject);
begin
  doAbout;
end;

procedure TForm1.WMSysCommand(var Msg: TWMSysCommand);
begin
  if Msg.CmdType = aboutMenuItem then
    doAbout
  else if Msg.CmdType = toggleMenuItem then
    doToggle
  else
    inherited;
end;


procedure TForm1.doToggle;
var
  sysMenu: HMenu;
begin
  sysMenu := GetSystemMenu(Self.handle, false);

  with Self.FileListBox1 do
  begin
    if(FileType * [ftDirectory] <> []) then
      begin
        FileType := FileType - [ftDirectory];
        toggle := false;
        ModifyMenu(sysMenu, 8, MF_BYPOSITION + MF_STRING + MF_UNCHECKED, toggleMenuItem, PChar('Toggle Folders'));
      end
    else
      begin
        FileType := FileType + [ftDirectory];
        toggle := true;
        ModifyMenu(sysMenu, 8, MF_BYPOSITION + MF_STRING + MF_CHECKED, toggleMenuItem, PChar('Toggle Folders'));
      end;
  end;

   WriteNewFolder('');
end;

procedure TForm1.doAbout;
begin
  MessageBoxW(Self.handle,
  PWideChar('Quick access to folders provided to you by the Elf. Provided under the terms of the GPL liscence.'),
  PWideChar('TrayFolders' + Version), MB_OK + MB_ICONINFORMATION + MB_RIGHT);
end;

procedure TForm1.Addnewfolder1Click(Sender: TObject);
var
  addFld: TForm2;
begin
  addFld := TForm2.Create(Self);

  addFld.ShowModal;

  if addFld.ModalResult = mrOk then
  begin
    WriteNewFolder(addFld.result);
    changeFolder := true;
    LoadDataInit;
  end;

  addFld.Free;
end;

procedure TForm1.doOpen;
var
  item: UnicodeString;
begin
  item := FileListBox1.FileName;
  if Pos('[', item) > 0 then
    begin
      Delete(item, pos('[', item), 1);
      Delete(item, pos(']', item), 1);
      FileListBox1.Directory := item;
    end
  else
    begin
      ShellExecute(Self.handle, 'open', PWideChar('"' + item + '"'), nil, nil, SW_SHOWNORMAL);
    end;
end;

procedure TForm1.Delete1Click(Sender: TObject);
var
  item: UnicodeString;
begin
  item := FileListBox1.FileName;

  if MessageBoxW(Self.handle, PWideChar('Delete ' +
    item), 'You sure?', MB_OKCANCEL + MB_ICONEXCLAMATION + MB_DEFBUTTON2)
    = IDOK then
  begin
    if FileExists(item) then
      DeleteFile(item)
    else
      MessageBoxW(self.handle, PWideChar('For reasons unbeknownst to me, the deletion failed!'), PWideChar('OUPS!'), MB_OK + MB_ICONERROR);

    //and reload the folder
    LoadFolder(currentMenuItem);
  end;

end;

procedure TForm1.DeleteCurrent1Click(Sender: TObject);
var
  f: TextFile;
  i: integer;
begin
  if MessageBoxA(Self.handle, 'Are you sure you want to delete this item?',
  'confirmation', MB_YESNO + MB_ICONQUESTION) = ID_NO then
    exit;


  AssignFile(f, dataFileLocation);
  rewrite(f);
  writeln(f, '; Try not to edit this file');
  writeln(f, '[fToggle]');
  if toggle then
    writeln(f, 'true')
  else
    writeln(f, 'false');
  writeln(f);
  writeln(f, '[noItems]');
  writeln(f, foldersLength - 1);
  writeln(f);
  writeln(f, '[Items]');
  for i := 0 to foldersLength - 1 do
  begin
    if i <> currentMenuItem then
      writeln(f, folders[i]);
  end;

  CloseFile(f);

  changeFolder := true;

  //if all folders were removed, revert to default settings
  if foldersLength <= 1 then
  begin
    DeleteFile(dataFileLocation);
  end;

  LoadDataInit;

end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
  Self.Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  menuItem, menuItem2: TMenuItem;
  i: integer;
  PpathW, PpathWnew: PWideChar;
  dest: UnicodeString;
  lengthOfExp: integer;

  sysMenu: HMenu;
begin
  //set randoms
  currentMenuItem := 0;
  FileListBox1.Directory := '';
  Application.MainFormOnTaskBar := true;
  SetWindowLong( application.handle, GWL_EXSTYLE,
     (GetWindowLong( application.handle, GWL_EXSTYLE )
     or WS_EX_TOOLWINDOW) and (not WS_EX_APPWINDOW) );
  SetWindowPos(Self.handle, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER + SWP_FRAMECHANGED);

  //set the folders
  foldersLength := 0;

  //load the config
  LoadDataInit;

  //Allow dragging and dropping
  FileBox1WindowProc := FileLIstBox1.WindowProc;
  FileLIstBox1.WindowProc := FileBox1NewWindowProc;
  DragAcceptFiles(FileListBox1.handle, true);


  //move to bottom right
  Self.Top := Screen.WorkAreaHeight - Self.Height;
  Self.Left := Screen.WorkAreaWidth - Self.Width;


  if foldersLength > 0 then
  begin
  //MessageDlg(folders[0], mtInformation, [mbOK], 0);
    FileListBox1.Directory := folders[0];
  end;

  //Transform the control (system) menu
  //get the handle to it
  sysMenu := GetSystemMenu(Self.handle, false);
  //add an separator
  AppendMenu(sysMenu, MF_SEPARATOR, 0, PChar(''));
  //add the toggle folders entry
  if(NOT toggle) then
  AppendMenu(sysMenu, MF_UNCHECKED, toggleMenuItem, PChar('Toggle Folders'))
  else
    begin
      AppendMenu(sysMenu, MF_CHECKED, toggleMenuItem, PChar('Toggle Folders'));
      doToggle;
    end;
  //add the about... entry
  AppendMenu(sysMenu, MF_STRING, aboutMenuItem, PChar('About...'));
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if Self.WindowState = wsMinimized then
  begin
    //hide the window like TOTALLY
    SetWindowPos(Self.handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_HIDEWINDOW);
    Visible := false;
  end;
end;

procedure TForm1.LoadData(s: UnicodeString);
var
  line, ss: string;
  f: textFile;
  noItems, count, n, i: integer;
  b: boolean;
begin
  assignFile(f, s);
  reset(f);

  while not eof(f) do
  begin
    readln(f, line);

    if line = '' then
      continue;
    if line[1] = ';' then
      continue;

    if line = '[fToggle]' then
    begin
      readln(f, line);
      if line = 'true' then toggle := true
      else toggle := false;
      continue;
    end;

    if line = '[noItems]' then
    begin
      readln(f, noItems);
      foldersLength := noItems;
      SetLength(folders, foldersLength);
      continue;
    end;

    if line = '[Items]' then
    begin
      count := 0;

      while not eof(f) do
      begin
        readln(f, line);

        if line = '' then
          continue;
        if line[1] = ';' then
          continue;
        if line[1] = '[' then
          break;
        if line = '' then
          break;

        if pos('%', line) > 0  then
        begin
          n := ExpandEnvironmentStrings(PWideChar(line), nil, 0);

          ss := '';
          for i := 1 to n do
            ss := ss + ' ';

          ExpandEnvironmentStrings(PWideChar(line), PWideChar(ss), n);
          line := ss;
          b := (length(line) = length(ss));
        end;

        if(count < foldersLength)   then
          folders[count] := line
        else
        begin
          CloseFile(f);
          DeleteFile(s);
          MessageDlg('Error occured. Please restart app.', mtError, [mbOK], 0);
          System.Halt(255);
          exit;
        end;
        inc(count);
      end;
    end;
  end;

  closeFile(f);
end;

procedure TForm1.FileListBox1DblClick(Sender: TObject);
begin
  doOpen;
end;

procedure TForm1.FileListBox1DragDrop(Sender, Source: TObject; X, Y: Integer);
begin
//  MessageDlg(source.tostring, mtInformation, [mbRetry], 0);
end;

procedure TForm1.FileListBox1DragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
//  Accept := true;
end;

procedure TForm1.FileListBox1KeyPress(Sender: TObject; var Key: Char);
begin
  if key = Chr(VK_RETURN) then
  begin
    doOpen;
  end;
end;

procedure TForm1.FileListBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  newItem: integer;
  thePoint: TPoint;
begin
  //when right-clicking, select the element under the mouse
  if Button = TMouseButton.mbRight then
  begin
    thePoint.X := X;
    thePoint.Y := Y;
    newItem := FileListBox1.ItemAtPos(thePoint, True);
    if newItem in [0..FileListBox1.Count] then //.Count-1?
    begin
      FileListBox1.Selected[newItem] := true;
    end;
  end;
end;

procedure TForm1.FileBox1NewWindowProc(var Msg: TMessage);
begin
  if Msg.Msg = WM_DROPFILES then
    FileBox1AfterDrop(TWMDROPFILES(Msg))
  else
    FileBox1WindowProc(Msg);
end;

procedure TForm1.CreateLink(source: PWideChar; where: PWideChar);
var
  IObject : IUnknown;
  ISLink : IShellLink;
  IPFile : IPersistFile;
  PIDL : PItemIDList;
  InFolder : UnicodeString;
  TargetName : String;
  LinkName : UnicodeString;
  FileName : UnicodeString;
  i: integer;
begin
  if MessageBoxW(0, PWideChar('Create shortcut of ' + source + ' in ' + where + '?'), PWideChar('Create shortcut?'), MB_YESNO + MB_ICONQUESTION) = IDYES then
  begin
    IObject := CreateComObject(CLSID_ShellLink);
    ISLink := IObject as IShellLink; //funny how i forgot about how delphi casts stuff in the rest of this program... oups :P
    IPFile := IObject as IPersistFile;

    InFolder := UnicodeString(where);
    if InFolder[length(InFolder)] <> '\' then
      InFolder := InFolder + '\';

    ISLink.SetPath(source) ;
    ISLink.SetWorkingDirectory(pChar(ExtractFilePath(UnicodeString(source)))) ;

    FileName := ExtractFileName(UnicodeString(source));
    for i:= length(Filename) downto 1 do
    begin
      if filename[i] = '.' then
        break;
    end;

    if i>1 then
    begin
      delete(FileName, i, length(filename) - i + 1);
      FileName := FileName + '.lnk';
    end;

    LinkName := InFolder + FileName;

    IPFile.Save(PWideChar(LinkName), false);

    LoadFolder(currentMenuItem);
  end;
end;

procedure TForm1.FileBOx1AfterDrop(var Msg: TWMDROPFILES);
var
  numFiles: longint;
  jet: longint;
  i: longint;
  bufferc: array [1..MAX_PATH] of WideChar;
begin
  numFiles := DragQueryFile(Msg.Drop, $FFFFFFFF, nil, 0);
  for i:=0 to numFiles - 1 do
  begin
    jet:=DragQueryFileW(Msg.Drop, i, nil, 0);

    DragQueryFileW(Msg.Drop, i, @bufferc, jet + 2);

    try
      //MessageBoxW(0, PWideChar(unicodestring(bufferc)), nil, 0);

      CreateLink(PWideChar(unicodestring(bufferc)), PWideChar(folders[currentMenuItem]));
    except
      on exception do
        continue;
    end;
  end;
end;

procedure TForm1.FolderItemClick(Sender: TObject);
begin
  //replace this thingamabob by getting the sender's name, lol
  currentMenuItem := ChangeMenu.Items.IndexOf(Sender as TMenuItem) - 2;
  if currentMenuItem < 0 then
    currentMenuItem := TrayMenu.Items.IndexOf(Sender as TMenuItem) - 4;

  LoadFolder(currentMenuItem);

  //replace THIS thingamabob with the new show/hide shit
  if Self.WindowState <> wsNormal then
    Self.WindowState := wsNormal;
	
  if not Visible then
  begin
    //show it
    SetWindowPos(Self.handle, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_SHOWWINDOW);
    //apparently needs to be top most window to become active
    SetActiveWindow(Self.handle);
    SetFocus;
    Visible := true;
    //revert state to normal if it wasn't
    Self.WindowState := wsNormal;
    //don't ask... somehow setting the window state back to awesome
    //sends it to the back of the row.

    //show it
    SetWindowPos(Self.handle, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_SHOWWINDOW);
    //apparently needs to be top most window to become active
    SetActiveWindow(Self.handle);
  end;
end;

procedure TForm1.LoadFolder(which: integer);
begin
  FileListBox1.Directory := folders[which];
end;

procedure TForm1.Open1Click(Sender: TObject);
begin
  doOpen;
end;

procedure TForm1.OpeninFolder1Click(Sender: TObject);
begin
    ShellExecute(Self.handle, 'open',
    PWideChar('"' + ExtractFileDir(FileListBox1.fileName)
    + '"'),
      nil, nil, SW_SHOWNORMAL);
end;

procedure TForm1.TrayIcon1Click(Sender: TObject);
begin
  //we use the self.visible property to know if the window is
  // shown/hidden by setwindowpos
  //this is because i have yet to discover how to figure
  // out if a window HAD been hidden or NOT using API calls
  if Visible then
  begin
    //hide it
    SetWindowPos(Self.handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_HIDEWINDOW);
    Visible := false;
  end
  else
  begin
    //show it
    SetWindowPos(Self.handle, HWND_TOP,0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_SHOWWINDOW);
    //apparently needs to be top most window to become active
    SetActiveWindow(Self.handle);
    SetFocus;
    Visible := true;
    //revert state to normal if it wasn't
    Self.WindowState := wsNormal;

    //will see
    //show it
    SetWindowPos(Self.handle, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_SHOWWINDOW);
    //apparently needs to be top most window to become active
    SetActiveWindow(Self.handle);
  end;
end;

//why does this even exist?!?!?! what is its raison d'etre?
function TForm1.GetFolder(s: UnicodeString): UnicodeString;
var
  ret: UnicodeString;
  i: integer;
begin
  ret := '';

  for i := length(s) downto 1 do
  begin
    if s[i] <> '\' then
      ret := s[i] + ret
    else
      break;
  end;

  GetFolder := ret;
end;

procedure TForm1.LoadDataInit;
var
  path, s: UnicodeString;
  menuItem: TMenuItem;
  f: TextFile;
  i: integer;
  oldMenuItems: array[1..6] of TMenuItem;
label noFile;
begin
  try
    path := GetEnvironmentVariable('APPDATA');
  except
    on exception do
      try
        path := GetEnvironmentVariable('UserProfile');
      except
        on exception do
          path := GetCurrentDir;
      end;
  end;

  if path[length(path)] <> '\' then
  begin
    path := path + '\';
  end;

  path := path + 'TrayFolders';
  s := path + '\config.ini';
  dataFileLocation := s;

  if FileExists(s) then
  begin
    try
      LoadData(s);
    except
      DeleteFile(s);
      LoadDataInit;
      exit;
    end;
  end
  else
  begin
    MessageBoxA(Self.Handle, 'There is no config file, one will be created in your appdata folder',
    'Minor Inconvenience', MB_OK);
    if not DirectoryExists(path) then
      CreateDir(path);

    assignFile(f, s);
    rewrite(f);

    writeln(f, '; Try to not edit this file');
    writeln(f, '[fToggle]');
    writeln(f, 'false');
    writeln(f);
    writeln(f, '[noItems]');
    writeln(f, 1);
    writeln(f);
    writeln(f, '[Items]');
    writeln(f, '%APPDATA%\Microsoft\Internet Explorer\Quick Launch');

    closeFile(f);

    LoadData(s);
  end;

  while TrayMenu.Items.Count > 4 do
  begin
    TrayMenu.Items.Delete(4);
  end;
  while ChangeMenu.Items.Count > 2 do
  begin
    ChangeMenu.Items.Delete(2);
  end;


  //set the menus with the newly aquired data
  with Self.TrayMenu.Items do
  begin
    for i := 0 to foldersLength - 1 do
    begin
      menuItem := TMenuItem.Create(Self);
      //menuItem.Caption := ExtractShortPathName(folders[i]);
      menuItem.Caption := folders[i];
      menuItem.OnClick := FolderItemClick;
      Add(menuItem);
    end;
  end;
  with Self.ChangeMenu.Items do
  begin
    for i := 0 to foldersLength - 1 do
    begin
      menuItem := TMenuItem.Create(Self);
      menuItem.Caption := folders[i];
      menuItem.OnClick := FolderItemClick;
      Add(menuItem);
    end;
  end;

  if changeFolder then
  begin
    currentMenuItem := 0;
    LoadFolder(0);
    changeFolder := false;
  end;

end;

procedure TForm1.WriteNewFolder(dir: UnicodeString);
var
  f: TextFile;
  i: integer;
begin
  if (DirectoryExists(dir)) or (dir='') then
  begin
    AssignFile(f, dataFileLocation);
    rewrite(f);
    writeln(f, '; Try not to edit this file');
    writeln(f, '[fToggle]');
      if toggle then
        writeln(f, 'true')
      else
        writeln(f, 'false');
    writeln(f);
    writeln(f, '[noItems]');
    if dir <> '' then
      writeln(f, foldersLength + 1)
    else
      writeln(f, foldersLength);
    writeln(f);
    writeln(f, '[Items]');
    for i := 0 to foldersLength - 1 do
    begin
      writeln(f, folders[i]);

    end;

    if dir <> '' then
      writeln(f, dir);

    CloseFile(f);
  end;
end;

end.

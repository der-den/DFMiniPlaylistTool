unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  DateUtils,
  EditBtn, ComCtrls, ExtCtrls, Buttons,FileUtil, Unit2;

type

  { TForm1 }

  TForm1 = class(TForm)
    ImageList_ToolBar: TImageList;
    ListBox: TListBox;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    StatusBar1: TStatusBar;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton_ItemSortAZ: TToolButton;
    ToolButton4: TToolButton;
    ToolButton_About: TToolButton;
    ToolButton_ItemRenameFile: TToolButton;
    ToolButton_SaveList: TToolButton;
    ToolButton_ReloadDir: TToolButton;
    ToolButton_ItemDown: TToolButton;
    ToolButton_ItemUp: TToolButton;
    ToolButton_ItemDeleteFile: TToolButton;
    ToolButton6: TToolButton;
    ToolButton_Open: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure ListBoxClick(Sender: TObject);
    procedure ToolButton_AboutClick(Sender: TObject);
    procedure ToolButton_ItemDeleteFileClick(Sender: TObject);
    procedure ToolButton_ItemMoveClick(Sender: TObject);
    procedure ToolButton_ItemRenameFileClick(Sender: TObject);
    procedure ToolButton_ItemSortAZClick(Sender: TObject);
    procedure ToolButton_OpenClick(Sender: TObject);
    procedure ToolButton_ReloadDirClick(Sender: TObject);
    function GetSelectedItem():integer;
    procedure ToolButton_SaveListClick(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

//
// iterate trough list an find the current selected item (first and only)
//
function TForm1.GetSelectedItem():integer;
var
  i : integer;
begin
  for i := 0 to ListBox.Count-1 do
     begin
       if ( ListBox.Selected[i] ) then
        begin
          Result := i;
          break;
        end;
     end;
end;


//
// Save current order of list to the file timestamps
//
procedure TForm1.ToolButton_SaveListClick(Sender: TObject);
var
  i : integer;
begin
  ToolButton_SaveList.Enabled:=false;
  for i:=0 to ListBox.Count-1 do
  begin

  end;
  //FileSetDate();
end;



//
// Select Item in list, read some meta data and show in statusbar
//
procedure TForm1.ListBoxClick(Sender: TObject);
var
  s : integer;
  fs : longint;

begin
  if (ListBox.SelCount > 0) then
   begin

     s := GetSelectedItem();
     fs := FileSize(ListBox.Items[s]);
     fs := fs Div 1024; // kb
     StatusBar1.SimpleText:=IntToStr(s+1)+' -- '+ListBox.Items[s]+', Filesize: '+IntToStr(fs)+' kb';

     ToolButton_ItemUp.Enabled:=true;
     ToolButton_ItemDown.Enabled:=true;
     ToolButton_ItemRenameFile.Enabled:=true;
     ToolButton_ItemDeleteFile.Enabled:=true;


     if (ListBox.Selected[0]) then begin
       ToolButton_ItemUp.Enabled:=false;
     end;

     if (ListBox.Selected[ListBox.Count-1]) then
     begin
       ToolButton_ItemDown.Enabled:=false;
     end;

  end;
end;


//
// Just a window with useless data ;-)
//
procedure TForm1.ToolButton_AboutClick(Sender: TObject);
begin
  Form2.Show();
end;

//
// Form create init settings
//
procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.Caption:='DFPlayer Mini Playlist Editor - v0.1';
end;

//
// Delete selected item
//
procedure TForm1.ToolButton_ItemDeleteFileClick(Sender: TObject);
var
  s : integer;
  f2d : string;
begin
  case QuestionDlg ('WARNING - Delete MP3 file','Delete mp3 file from your directory/device? Are you sure?',mtCustom,[mrYes,'Yes', mrNo, 'No', 'IsDefault'],'') of
        mrYes: begin
                  if (ListBox.SelCount > 0) then
                  begin

                     s := GetSelectedItem();
                     f2d := ListBox.Items[s];
                     if( FileIsReadOnly(f2d) ) then
                     begin
                        QuestionDlg ('ERROR','File is read-only',mtCustom,[mrOK,'OK'],'');
                     end else
                     begin
                        DeleteFile(f2d);
                        ToolButton_ReloadDirClick(Sender);
                     end;

                  end;

               end;

  end;
end;


//
// Move selected item up or down in list
//
procedure TForm1.ToolButton_ItemMoveClick(Sender: TObject);
var
  s,st : Integer;
  temp : string;
begin
  s:= GetSelectedItem();

  if( TToolButton(Sender).Name = 'ToolButton_ItemDown') then st:=s+1 else st:=s-1;
  temp := ListBox.Items[st];
  ListBox.Items[st] := ListBox.Items[s];
  ListBox.Items[s] := temp;
  ListBox.Selected[s] := false;
  ListBox.Selected[st] := true;
  ListBoxClick(Sender);
end;


//
// Rename selected file and item
//
procedure TForm1.ToolButton_ItemRenameFileClick(Sender: TObject);
var
  newFileName : string;
  s : integer;
begin
  s := GetSelectedItem();

  newFileName := ListBox.Items[s];
  if InputQuery('Rename file', 'Insert new filename and dont forget mp3 extension.', false, newFileName)   then
  begin
      if RenameFile(ListBox.Items[s],newFileName) then
      begin
         ListBox.Items[s] := newFileName;
      end;
  end;
end;

//
// activate short sorting of list object - results in a alphabetical order
//
procedure TForm1.ToolButton_ItemSortAZClick(Sender: TObject);
begin
  ListBox.Sorted:=true;
  ListBox.Sorted:=false;
end;

//
// open select dir dialog and read mp3 to list (via Reload)
//
procedure TForm1.ToolButton_OpenClick(Sender: TObject);
begin
  if SelectDirectoryDialog1.Execute() then
  begin
    ToolButton_ReloadDirClick(Sender);
  end;
end;


//
// Read mp3 from directory to list in timestamp order
//
procedure TForm1.ToolButton_ReloadDirClick(Sender: TObject);
var
  i,LIndex: Integer;

  LSearchRec: TSearchRec;
  FList2Sort : TStringList;

  CreateDT, AccessDT, ModifyDT: TDateTime;
  s : string;
begin
   ListBox.Items.Clear;

   FList2Sort := TStringList.Create();

   // need DFPLayer create or mod timestamp?
   if FindFirst(SelectDirectoryDialog1.FileName + '\*.mp3', 0, LSearchRec) = 0 then
   begin
    try
      repeat
        with LSearchRec do
                s := Format('%s - %s', [
          LSearchRec.Name,
          FormatDateTime('dd.mm.yyyy hh:nn sss zzz', UniversalTimeToLocal(UnixToDateTime(LSearchRec.Time)))
      ]);

     //   CreateDT := FileTimeToDTime(LSearchRec.FindData.ftCreationTime);
     //   AccessDT := FileTimeToDTime(LSearchRec.FindData.ftLastAccessTime);
     //   ModifyDT := FileTimeToDTime(LSearchRec.FindData.ftLastWriteTime);

        FList2Sort.Add(IntToHex(LSearchRec.Time, 8) + '=' + LSearchRec.Name);
        ListBox.Items.Add(s);
      until FindNext(LSearchRec) <> 0;
    finally
      FindClose(LSearchRec);
    end;
   end;

   FList2Sort.Sort;

   //for i:=0 to FList2Sort.Count-1 do begin
   //   ListBox.Items.Add(FList2Sort.Names[i] + '-'+FList2Sort.Values[FList2Sort.Names[i]]);
   //end;

   ListBox.Items.AddStrings(FList2Sort);





   StatusBar1.SimpleText:=IntToStr(ListBox.Count)+' Items in '+SelectDirectoryDialog1.FileName;

   ToolButton_ReloadDir.Enabled:=true;
   ToolButton_ItemSortAZ.Enabled:=true;
   ToolButton_ItemUp.Enabled:=false;
   ToolButton_ItemDown.Enabled:=false;
   ToolButton_ItemRenameFile.Enabled:=false;
   ToolButton_ItemDeleteFile.Enabled:=false;
end;

end.


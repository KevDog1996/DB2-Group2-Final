USE [DOOMSDAY]
GO

CREATE TRIGGER personItemsToSettlement ON People
AFTER UPDATE 
AS 

IF((Select Alive From inserted) = 1 and (Select Alive From deleted) = 0) 
Begin
    DECLARE @PersonID varchar(8);

    SET @PersonID = (Select PersonID From inserted i);

    Declare @TableSize int;

    Set @TableSize = (Select Count(PersonID) From PersonItemInventory Where PersonID = @PersonID)

    Declare @X int;

    Set @X = 0;

    Begin

        Declare @Table Table(PersonID Varchar(8),ItemID Varchar(8),Quantity int,RowNumber int)
    
        Insert into @Table Select PersonID,ItemID,Quantity,ROW_NUMBER() OVER(ORDER BY ItemID)-1 as RowNumber From PersonItemInventory Where PersonID = @PersonID



        While @X < @TableSize
        Begin
            Update SettlementsItemInventory
            Set Quantity = Quantity + (Select Quantity From @Table Where RowNumber = @X)
        Where
            ItemID = (Select ItemID From @Table where RowNumber = @X);
        SET @X+=1;
        End

        Delete From PersonItemInventory Where PersonItemInventory.PersonID = @PersonID

    End
    Begin
        Set @X = 0;

        Insert into SettlementsFoodInventory Select (SELECT SettlementID FROM inserted) AS SettlementID, FoodID, Quantity, AcquireDate From PersonFoodInventory Where PersonID = @PersonID

        Delete From PersonItemInventory Where PersonItemInventory.PersonID = @PersonID
    End
    Begin
        Set @X = 0;

        Declare @Table3 Table(PersonID Varchar(8),WeaponID Varchar(8),Quantity int,RowNumber int);

        Insert into @Table3 Select PersonID,WeaponID,Quantity,ROW_NUMBER() OVER(ORDER BY WeaponID)-1 as RowNumber From PersonWeaponInventory Where PersonID = @PersonID;

        Set @TableSize = (Select Count(PersonID) From PersonWeaponInventory Where PersonID = @PersonID);

        While @X < @TableSize
        Begin
            Update SettlementsWeaponInventory
            Set Quantity = Quantity + (Select Quantity From @Table Where RowNumber = @X)
                Where
            WeaponID = (Select WeaponID From @Table where RowNumber = @X);
            SET @X += 1;
        End

        Delete From PersonItemInventory Where PersonItemInventory.PersonID = @PersonID;
    End
    Begin
        Set @X = 0;

        Declare @Table4 Table(PersonID Varchar(8),CurrencyID Varchar(8),Quantity int,RowNumber int);

        Insert into @Table4 Select PersonID,CurrencyID,Quantity,ROW_NUMBER() OVER(ORDER BY CurrencyID)-1 as RowNumber From PersonCurrencyInventory Where PersonID = @PersonID;

        Set @TableSize = (Select Count(PersonID) From PersonCurrencyInventory Where PersonID = @PersonID);

        While @X < @TableSize
        Begin
            Update SettlementCurrencyInventory
            Set Quantity = Quantity + (Select Quantity From @Table Where RowNumber = @X)
                Where
            CurrencyID = (Select CurrencyID From @Table where RowNumber = @X);
            SET @X += 1;
        End

        Delete From PersonCurrencyInventory Where PersonCurrencyInventory.PersonID = @PersonID;
    End

    Delete From PeopleOccupation where PersonID = @PersonID;
    Delete From PeopleSkills where PersonID = @PersonID;

End

CREATE TRIGGER deadInsteadOfDelete ON People
INSTEAD OF DELETE
AS
BEGIN
	IF (Select Alive FROM deleted) = 0
		BEGIN
			DECLARE @PersonID varchar(8);
			SET @PersonID = (Select PersonID FROM deleted i);
			RAISERROR('Cannot Delete Person',16,1);
			ROLLBACK;
			UPDATE People
				Set Alive = 1
			WHERE
				PersonID = @PersonID
		END
	ELSE
		BEGIN
			DELETE FROM People WHERE PersonID = (Select PersonID FROM deleted)
		END
END

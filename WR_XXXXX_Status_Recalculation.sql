--********************************************************************************************************
-- Author*:			Alex Tierney
-- Update Date:		June 05, 2013
-- Work Request*:	xxxxxx 
-- Rave Version Developed For*: 5.6.3, 5.6.1, 5.6.4
-- URL*:  [URL].mdsol.com
-- Module*: EDC
-- DT# (if applicable): N/A
--********************************************************************************************************

--********************************************************************************************************
-- Description*: Status icons are incorrect for two specific subjects in the below indicated study.  This
-- script marks the two subjects for status recalcluation.  This URL does not have script utility or the 
--'Mark Subjects for Status Recalcluation' script.
--
-- Keywords: Status Icon, Incorrect Status, Rollup
--THIS IS AN UPDATE--
--********************************************************************************************************
declare		@StudyTypeID int,
			@StudySiteTypeID int,
			@SubjectTypeID int,
			@InstanceTypeID int,
			@DatapageTypeID int,
			@RecordTypeID int,
			@DatapointTypeID int

select @StudyTypeID = ObjectTypeID from objecttyper where ObjectName = 'Medidata.Core.Objects.Study'
select @StudySiteTypeID = ObjectTypeID from objecttyper where ObjectName = 'Medidata.Core.Objects.StudySite'
select @SubjectTypeID = ObjectTypeID from objecttyper where ObjectName = 'Medidata.Core.Objects.Subject'
select @InstanceTypeID = ObjectTypeID from objecttyper where ObjectName = 'Medidata.Core.Objects.Instance'
select @DatapageTypeID = ObjectTypeID from objecttyper where ObjectName = 'Medidata.Core.Objects.DataPage'
select @RecordTypeID = ObjectTypeID from objecttyper where ObjectName = 'Medidata.Core.Objects.Record'
select @DatapointTypeID = ObjectTypeID from objecttyper where ObjectName = 'Medidata.Core.Objects.DataPoint'

select st.StudyID, ss.StudySiteID, s.SubjectID, dpg.DataPageID, r.RecordID, dp.DataPointID
into #tmp
from dbo.Projects p
inner join dbo.Studies st on st.ProjectID = p.ProjectID
inner join dbo.StudySites ss on ss.StudyID = st.StudyID
inner join dbo.Subjects s on s.StudySiteID = ss.StudySiteID
inner join dbo.DataPages dpg on dpg.SubjectID = s.SubjectID
inner join dbo.Records r on r.DataPageID = dpg.DataPageID
left join dbo.DataPoints dp on dp.RecordID = r.RecordID 
where 1=1
	and dbo.fnlocaldefault(projectName) = '[project]' -- update
    and dbo.fnlocaldefault(environmentNameID) = '[study]'
	and s.subjectname = '[subject]'

select distinct i.InstanceID
into #Instances
from #tmp t
inner join dbo.Instances i on i.SubjectID = t.SubjectID
	

update objectstatusallroles
set ExpirationDate = '1900-01-01 00:00:00.000'
from #tmp t
inner join objectstatusallroles os on os.ObjectId = t.DataPointID and os.ObjectTypeId = @DatapointTypeID

update objectstatusallroles
set ExpirationDate = '1900-01-01 00:00:00.000'
from #tmp t
inner join objectstatusallroles os on os.ObjectId = t.RecordID and os.ObjectTypeId = @RecordTypeID

update objectstatusallroles
set ExpirationDate = '1900-01-01 00:00:00.000'
from #tmp t
inner join objectstatusallroles os on os.ObjectId = t.DataPageID and os.ObjectTypeId = @DatapageTypeID

update objectstatusallroles
set ExpirationDate = '1900-01-01 00:00:00.000'
from #Instances t
inner join objectstatusallroles os on os.ObjectId = t.InstanceID and os.ObjectTypeId = @InstanceTypeID

update objectstatusallroles
set ExpirationDate = '1900-01-01 00:00:00.000'
from #tmp t
inner join objectstatusallroles os on os.ObjectId = t.SubjectID and os.ObjectTypeId = @SubjectTypeID

update objectstatusallroles
set ExpirationDate = '1900-01-01 00:00:00.000'
from #tmp t
inner join objectstatusallroles os on os.ObjectId = t.StudySiteID and os.ObjectTypeId = @StudySiteTypeID

update objectstatusallroles
set ExpirationDate = '1900-01-01 00:00:00.000'
from #tmp t
inner join objectstatusallroles os on os.ObjectId = t.StudyID and os.ObjectTypeId = @StudyTypeID



update dbo.Records
set NeedsCVRefresh = 1
from #tmp t
inner join dbo.Records r on r.RecordID = t.RecordID



--------------------------------------------------------------------------- 
-- force status recalculations
---------------------------------------------------------------------------

select distinct StudySiteID, -2 as RoleID, getUTCDate() as Dirty, studyID
into #StatusRollupQueue
from #tmp

update t 
set t.RoleID = ro.roleID
from #StatusRollupQueue t
	join userStudyRole usr
		on usr.studyID = t.studyID
	join roles ro
		on ro.roleID = usr.roleID 
			and ro.active = 1
			and ro.roleID > 0



INSERT INTO StatusRollupQueue (ObjectTypeID, ObjectID, RoleID, Dirty)
SELECT distinct @StudySiteTypeID, StudySiteID, RoleID, getUTCDate()
FROM #StatusRollupQueue
	

-- Clean up
drop table #tmp
drop table #Instances
drop table #StatusRollupQueue

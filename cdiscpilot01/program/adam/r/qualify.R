# Independent, invented subjects: no study rows or reference outputs are used.
suppressPackageStartupMessages(library(arrow))
library(yamaa)
library(yaml)
root <- normalizePath(commandArgs(TRUE)[[1]])
stopifnot(as.character(packageVersion('yamaa')) == '0.5.0')
fixture <- tempfile('yamaa-synthetic-')
for(dir in c('spec/yamaa','data/sdtm','data/adam','log')) dir.create(file.path(fixture,dir),recursive=TRUE)
subject <- data.frame(USUBJID=c('TEST-A','TEST-B'),STUDYID='TEST',SITEID='1',SITEGR1='1',TRTSDT=as.Date('2026-01-01'),TRTEDT=as.Date('2026-12-31'),TRT01P='A',TRT01PN=1,AGE=60,AGEGR1='<65',AGEGR1N=1,RACE='WHITE',RACEN=1,SEX='F',ITTFL='Y',EFFFL='Y',COMP24FL='N')
write_parquet(subject,file.path(fixture,'data/adam/adsl-yamaa.parquet'))
observation <- function(subject,code,day,sequence,value,baseline='') data.frame(USUBJID=subject,QSTESTCD=code,QSDY=day,QSSEQ=sequence,QSSTRESN=value,VISIT=paste('DAY',day),VISITNUM=sequence,QSDTC=if(day==85)''else as.character(as.Date('2026-01-01')+day-1),QSBLFL=baseline)
qs <- do.call(rbind,list(
 observation('TEST-A','ACTOT',1,1,10,'Y'),observation('TEST-A','ACTOT',56,2,12),
 observation('TEST-A','ACTOT',70,3,18),observation('TEST-A','ACTOT',84,4,19),
 observation('TEST-A','ACTOT',85,5,20),
 observation('TEST-A','ACITM01',1,6,5,'Y'),observation('TEST-A','ACITM01',56,7,NA_real_),
 observation('TEST-A','ACITM01',85,8,7),
 observation('TEST-A','CIBIC',2,9,3),observation('TEST-A','CIBIC',56,10,4),observation('TEST-A','CIBIC',70,11,5),
 observation('TEST-B','ACTOT',1,99,0,'Y'),observation('TEST-B','ACTOT',50,101,6),observation('TEST-B','ACTOT',62,100,8)))
write_parquet(qs,file.path(fixture,'data/sdtm/qs.parquet'))
for(ds in c('adqsadas','adqscibc')) {
 text<-readLines(file.path(root,'spec/yamaa',paste0(ds,'.yaml')))
 text<-text[!grepl('schema: adsl.yaml',text,fixed=TRUE)]
 path<-file.path(fixture,'spec/yamaa',paste0(ds,'.yaml'));writeLines(text,path)
 spec<-yamaa_spec(path); checked<-spec$check();stopifnot(nrow(checked$issues)==0L)
 result<-spec$run();if(nrow(result$issues))print(result$issues)
 stopifnot(nrow(result$issues)==0L);result$save()
}
a<-read_parquet(file.path(fixture,'data/adam/adqsadas-yamaa.parquet'))
c<-read_parquet(file.path(fixture,'data/adam/adqscibc-yamaa.parquet'))
# Hand-authored expected values for original and generated total-score records.
expected<-data.frame(USUBJID=c(rep('TEST-A',6),rep('TEST-B',5)),
 QSSEQ=c(1,2,3,4,5,5,99,101,100,100,100),
 AVISITN=c(0,8,8,8,16,24,0,8,8,16,24),
 AVAL=c(10,12,12,12,20,20,0,6,6,6,6),
 ANL01FL=c('Y','Y','','','Y','Y','Y','Y','','Y','Y'),
 DTYPE=c('','','LOCF','LOCF','','LOCF','','','LOCF','LOCF','LOCF'))
expected<-expected[order(expected$USUBJID,expected$AVISITN,expected$QSSEQ),]
actual<-a[a$PARAMCD=='ACTOT',names(expected)]
rownames(actual)<-NULL
print(actual);print(expected)
stopifnot(isTRUE(all.equal(actual,expected,check.attributes=FALSE)))
stopifnot(is.na(a$AVAL[a$QSSEQ==7]),is.na(a$CHG[a$QSSEQ==7]),
 all(is.na(a$PCHG[a$USUBJID=='TEST-B'])),all(is.na(a$ADT[a$QSSEQ==5])))
expected_c<-data.frame(QSSEQ=c(9,10,11,11,11),AVISITN=c(8,8,8,16,24),
 AVAL=c(3,4,5,4,4),ANL01FL=c('','Y','','Y','Y'),DTYPE=c('','','','LOCF','LOCF'))
stopifnot(isTRUE(all.equal(as.data.frame(c[names(expected_c)]),expected_c,check.attributes=FALSE)))
# Explicit arithmetic association matters for strict IEEE-754 equality.
stopifnot(100*(11-3)/3 != (11-3)/3*100)
# Saved metadata reproducer: labels are declared, but R 0.5.0 omits them.
table<-read_parquet(file.path(fixture,'data/adam/adqsadas-yamaa.parquet'),as_data_frame=FALSE)
stopifnot(is.null(table$schema$fields[[1]]$metadata[['yamaa:label']]))
cat('PASS: invented ADAS/CIBC rank, tie, window boundary, LOCF donor/value, missing score, zero baseline, invalid date, exact arithmetic, and missing serialized label cases.\n')

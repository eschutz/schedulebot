-- wheredb table initialisation script

create schema UserEvents;

create table UserEvents.Events(
  "User" text not null,
  Type varchar(11) not null,
  StartingTime text not null,
  FinishingTime text not null,
  Activity text not null,
  ID text primary key not null
);

create table UserEvents.UserData(
  UserDistinct text primary key not null,
  Timezone text not null
);

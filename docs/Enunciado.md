# Mobile Development Project - 2026-10 - Peer Assessment App


- Team Size: 4 students per group

## Project Overview

Students will develop a mobile application using Flutter that allows students to evaluate the performance and commitment of their peers in collaborative course activities.

### Important context (AS-IS):

Groups are not created in the app. They are formed in Brightspace (group categories) and imported into the app.

## Functional Requirements

### 🧑‍🏫 Courses and Roles

- Two types of users, **teachers** and **students** (one app with roles, or two apps—team decides and justifies)

- A teacher can **invite users** to join a course. Invitations must be private or include a **verification method**.

- A teacher can have **multiple courses**.

- A student can join **multiple courses**.

### 👥 Groups

- Groups are formed on brightspace (known as **group categories**) and imported into the app (**updates are also possible**).

- Multiple group categories are possible on one course

### 📝 Activities and assessment

- Teachers can **trigger assessments** on any **category** of the course.

### Assessment Parameters

An assessment gives each member of a group the opportunity to evaluate the work and attitude of its peers; **there is no self-evaluation.**

Each assessment includes:

- **Name**

- **Time window** (duration of availability in minutes or hours)

- **Visibility**:
  - **Public**: results are shown to the group members (criteria scores + general score).

  - **Private**: results are visible only to the teacher.

### Scoring Access

Teachers can view:

- **Activity average** (all groups)

- **Group average** (across activities)

- **Student average** (across activities)

- **Detailed results** per group > student > criteria score


## 📊 Assessment Criteria

| Criterios     | Needs Improvement (2.0)                                                              | Adequate (3.0)                                                                         | Good (4.0)                                                                                 | Excellent (5.0)                                                                          |
|---------------|--------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| Punctuality   | Was late or absent for most sessions, negatively impacting the team's performance.   | Frequently arrived late or missed sessions.                                            | Was generally punctual and attended most sessions.                                         | Was consistently punctual and attended all team sessions.                                |
| Contributions | Acted mostly as a passive observer, contributed little or nothing to the team.       | Participated occasionally in discussions and teamwork.                                 | Made several contributions; could be more critical or proactive.                           | Provided relevant and enriching contributions that improved the team's work.             |
| Commitment    | Showed little commitment to tasks or roles, both with the facilitator and teammates. | Occasionally showed lack of commitment, which affected team progress.                  | Demonstrated responsibility and commitment most of the time, though could contribute more. | Consistently committed to tasks and roles, showing strong engagement with the team.      |
| Attitude      | Displayed a negative or indifferent attitude toward team tasks and collaboration.    | Occasionally showed a positive attitude, but not enough to positively impact the team. | Mostly displayed a positive and open attitude that helped the team.                        | Always demonstrated a positive attitude and willingness to contribute with quality work. |



## 🧠 Coding requirements

1. The app must adhere to the clean architecture principles given in class.

2. The app must use GetX as its state management, navigation and dependency injectors.

3. Make sure location and background work permissions are requested and given.

4. Authentication and data storage services should use ([Roble](https://roble.openlab.uninorte.edu.co/docs))
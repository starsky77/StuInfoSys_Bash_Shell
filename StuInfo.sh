#!/bin/bash
#!/bin/awk -f

#教师数据
#数据格式（教师ID，教师姓名，所属院系，账户密码）
DBTeacherInfoPath="./DBFile/DBTeacherInfo.txt"
#课程数据
#数据格式（课程ID，课程名称，课程信息）
DBCourserInfoPath="./DBFile/DBCourseInfo.txt"
#学生数据
#数据格式（学生ID，学生姓名，所属院系，账户密码）
DBStuInfoPath="./DBFile/DBStuInfo.txt"
#课程与教师绑定关系的数据
#数据格式（教师ID，课程ID）
DBTeacher_CoursePath="./DBFile/DBTea_Course.txt"
#课程内学生的数据
#数据格式（课程ID，学生ID，学生姓名）
DBClassPath="./DBFile/DBClass.txt"
#作业数据
#数据格式（作业ID，课程ID，作业名称，作业类型，作业信息）
DBHomeWorkPath="./DBFile/DBHomeWork.txt"
#学生作业完成情况数据
#数据格式（作业ID，学生ID，学生姓名，作业完成情况）
DBStuHomeWorkPushPath="./DBFile/StuHomeWorkPush.txt"

connect_teacher_course() {
    export existFlag=false
    echo "输入要绑定的教师工号"
    read TeacherID
    while read line; do
        TeacherID_read=${line/,*/}
        if [ "$TeacherID_read" = "$TeacherID" ]; then
            {
                export existFlag=true
                break
            }
        fi
    done <$DBTeacherInfoPath

    if [ "$existFlag" = "false" ]; then
        {
            echo "输入的教师工号$TeacherID不存在于教师信息记录文件中($DBTeacherInfoPath)"
            return
        }
    fi

    export existFlag=false
    echo "输入要绑定的课程ID"
    read courseID
    while read line; do
        CourseID=${line/,*/}
        if [ "$CourseID" = "$courseID" ]; then
            {
                export existFlag=true
                break
            }
        fi
    done <$DBCourserInfoPath

    if [ "$existFlag" = "false" ]; then
        {
            echo "输入的课程ID$courseID不存在于课程信息记录文件中($DBCourserInfoPath)"
            return
        }
    fi

    echo "$TeacherID,$courseID" >>$DBTeacher_CoursePath
    echo "课程绑定成功，其的记录为($TeacherID,$courseID)"

}

disconnect_teacher_course() {
    echo "输入要解绑的教师ID："
    read teacherID
    echo "输入要解绑的课程ID：（当这一对关系不存在时则对数据没有任何影响）"
    read courseID

    sed "/^$teacherID,$courseID/d" $DBTeacher_CoursePath >output
    mv -f output $DBTeacher_CoursePath
    echo "解绑完成"
}

List_teacher_course() {
    echo "=================================================="
    echo "教师ID ： 课程ID"
    cat $DBTeacher_CoursePath
}

InsertStuInfo() {
    echo "请输入要加入的学生ID(若学院记录文件中存在，则插入失败)："
    read StuInfo
    export existFlag=false
    while read line; do
        lineStuInfo=${line/,*/}
        if [ "$lineStuInfo" = "$StuInfo" ]; then
            {
                export existFlag=true
                break
            }
        fi
    done <$DBStuInfoPath

    if [ "$existFlag" == "true" ]; then
        {
            export existFlag=false
            echo "学生ID已存在，插入失败"
        }
    else
        {
            echo "请输入学生名称: "
            read StuName
            echo "请输入学生所属学院："
            read StuDepart
            echo "请输入学生密码："
            read password
            echo "$StuInfo,$StuName,$StuDepart,$password" >>$DBStuInfoPath
            echo "学生信息插入成功,插入的记录为($StuInfo,$StuName,$StuDepart,$password)"
        }
    fi

}

ChangeStuInfo() {
    echo "请输入要修改的学生ID："
    read StuID
    stringLine=$(grep $StuID $DBStuInfoPath)
    if [ "$stringLine" != "" ]; then
        {
            StuName=$(echo "$stringLine" | awk -F',' '{print $2}')
            StuDepart=$(echo "$stringLine" | awk -F',' '{print $3}')
            PassWord=$(echo "$stringLine" | awk -F',' '{print $4}')

            echo "要更新的学生信息为:$stringLine"
            echo "输入要更改的信息(1.姓名 2.院系 3.密码(1 or 2 or 3)):"
            read subCommand
            case $subCommand in
            1)
                echo "请输入学生的新姓名： "
                read newStuName

                sed  "/^$StuID/d" $DBStuInfoPath >$DBStuInfoPath"_back"
                mv -f $DBStuInfoPath"_back" $DBStuInfoPath

                echo "$StuID,$newStuName,$StuDepart,$PassWord" >>$DBStuInfoPath
                echo "更新学生记录成功($StuID,$newStuName,$StuDepart,$PassWord)"
                ;;
            2)
                echo "请输入院系名称： "
                read newStuDepart

                sed  "/^$StuID/d" $DBStuInfoPath >$DBStuInfoPath"_back"
                mv -f $DBStuInfoPath"_back" $DBStuInfoPath
                echo "$StuID,$StuName,$newStuDepart,$PassWord" >>$DBStuInfoPath
                echo "更新学生记录成功($StuID,$StuName,$newStuDepart,$PassWord)"
                ;;
            3)
                echo "请输入密码： "
                read newPassWord

                sed  "/^$StuID/d" $DBStuInfoPath >$DBStuInfoPath"_back"
                mv -f $DBStuInfoPath"_back" $DBStuInfoPath
                echo "$StuID,$StuName,$newStuDepart,$newPassWord" >>$DBStuInfoPath
                echo "更新学生记录成功($StuID,$StuName,$StuDepart,$newPassWord)"
                ;;

            *)
                echo "输入有误，更新失败!"
                ;;
            esac
        }
    else
        {
            echo "不存在该学生ID！"
        }
    fi
}

DeleteStuInfo() {
    echo "输入要删除的学生ID"
    read StuID
    export existFlag=false
    export delCount=0
    export delLine=0
    while read line; do
        lineStuID=${line/,*/}
        if [ "$lineStuID" = "$StuID" ]; then
            {
                StuName=$(echo "$line" | awk -F',' '{print $2}')
                StuDepart=$(echo "$line" | awk -F',' '{print $3}')
                PassWord=$(echo "$line" | awk -F',' '{print $4}')
                export existFlag=true
                break
            }
        fi
    done <$DBStuInfoPath
    if [ "$existFlag" = "true" ]; then
        {
            export existFlag=false
            sed "/^$StuID,$StuName,$StuDepart,$PassWord/d" $DBStuInfoPath >$DBStuInfoPath"_back"
            mv -f $DBStuInfoPath"_back" $DBStuInfoPath
            echo "删除学生账户成功：被删除的学生ID$StuID"
        }
    else
        {
            echo "学生记录文件中不存在学生ID$StuID,删除失败"
        }
    fi

}

ListStuInfo() {
    echo "=================================================="
    echo "学生ID ： 学生姓名 ：所属院系 ： 账户密码"
    cat $DBStuInfoPath

}

InsertTeacherInfo() {
    echo "请输入要加入的教师工号(若学院记录文件中存在，则插入失败)："
    read TeacherInfo
    export existFlag=false
    while read line; do
        lineTeacherInfo=${line/,*/}
        if [ "$lineTeacherInfo" = "$TeacherInfo" ]; then
            {
                export existFlag=true
                break
            }
        fi
    done <$DBTeacherInfoPath

    if [ "$existFlag" == "true" ]; then
        {
            export existFlag=false
            echo "教师工号已存在，插入失败"
        }
    else
        {
            echo "请输入教师名称: "
            read teacherName
            echo "请输入教师所属学院："
            read TeacherDepart
            echo "请输入教师密码："
            read password
            echo "$TeacherInfo,$teacherName,$TeacherDepart,$password" >>$DBTeacherInfoPath
            echo "教师信息插入成功,插入的记录为($TeacherInfo,$teacherName,$TeacherDepart,$password)"
        }
    fi

}

ChangeTeacherInfo() {
    echo "请输入要修改的教师工号："
    read teacherID
    stringLine=$(grep $teacherID $DBTeacherInfoPath)
    if [ "$stringLine" != "" ]; then
        {
            TeacherName=$(echo "$stringLine" | awk -F',' '{print $2}')
            TeacherDepart=$(echo "$stringLine" | awk -F',' '{print $3}')
            PassWord=$(echo "$stringLine" | awk -F',' '{print $4}')

            echo "要更新的教师信息为:$stringLine"
            echo "输入要更改的信息(1.姓名 2.院系 3.密码(1 or 2 or 3)):"
            read subCommand
            case $subCommand in
            1)
                echo "请输入教师的新姓名： "
                read newTeacherName

                sed "/^$teacherID/d" $DBTeacherInfoPath >$DBTeacherInfoPath"_back"
                mv -f $DBTeacherInfoPath"_back" $DBTeacherInfoPath
                echo "$teacherID,$newTeacherName,$TeacherDepart,$PassWord" >>$DBTeacherInfoPath
                echo "更新教师记录成功($teacherID,$newTeacherName,$TeacherDepart,$PassWord)"
                ;;
            2)
                echo "请输入院系名称： "
                read newTeacherDepart

                sed "/^$teacherID/d" $DBTeacherInfoPath >$DBTeacherInfoPath"_back"
                mv -f $DBTeacherInfoPath"_back" $DBTeacherInfoPath
                echo "$teacherID,$TeacherName,$newTeacherDepart,$PassWord" >>$DBTeacherInfoPath
                echo "更新教师记录成功($teacherID,$TeacherName,$newTeacherDepart,$PassWord)"
                ;;
            3)
                echo "请输入密码： "
                read newPassWord

                sed "/^$teacherID/d" $DBTeacherInfoPath >$DBTeacherInfoPath"_back"
                mv -f $DBTeacherInfoPath"_back" $DBTeacherInfoPath
                echo "$teacherID,$TeacherName,$newTeacherDepart,$newPassWord" >>$DBTeacherInfoPath
                echo "更新教师记录成功($teacherID,$TeacherName,$TeacherDepart,$newPassWord)"
                ;;

            *)
                echo "输入有误，更新失败!"
                ;;
            esac
        }
    else
        {
            echo "不存在该教工ID！"
        }
    fi
}

DeleteTeacherInfo() {
    echo "输入要删除的教师工号"
    read teacherID
    export existFlag=false
    export delCount=0
    export delLine=0
    while read line; do
        lineteacherID=${line/,*/}
        if [ "$lineteacherID" = "$teacherID" ]; then
            {
                TeacherName=$(echo "$line" | awk -F',' '{print $2}')
                TeacherDepart=$(echo "$line" | awk -F',' '{print $3}')
                PassWord=$(echo "$line" | awk -F',' '{print $4}')
                export existFlag=true
                break
            }
        fi
    done <$DBTeacherInfoPath
    if [ "$existFlag" = "true" ]; then
        {
            export existFlag=false
            sed "/^$teacherID,$TeacherName,$TeacherDepart,$PassWord/d" $DBTeacherInfoPath >$DBTeacherInfoPath"_back"
            mv -f $DBTeacherInfoPath"_back" $DBTeacherInfoPath

            echo "删除教师账户成功：被删除的教师工号：$teacherID"
        }
    else
        {
            echo "教师记录文件中不存在教师工号$teacherID,删除失败"
        }
    fi

}

ListTeacherInfo() {
    echo "=================================================="
    echo "教师工号 ： 教师姓名 ：所属院系 ： 账户密码"
    cat $DBTeacherInfoPath

}

InsertCourseInfo() {
    echo "请输入课程ID(如果文件中已存在则插入失败!): "
    read CourseID
    export existFlag=false
    #判断是否存在编号和输入的一样的学生记录
    while read line; do
        lineCourseID=${line/,*/}
        #echo "数字$lineCourseID,数字2$CourseID"
        if [ "$lineCourseID" = "$CourseID" ]; then
            {
                export existFlag=true
                break
            }
        fi
    done <$DBCourserInfoPath

    #echo "$existFlag"
    if [ "$existFlag" = "true" ]; then
        echo "输入的编号$CourseID已经存在了，插入失败！"
    else
        {
            export existFlag=false
            echo "请输入该课程的名称："
            read CourseName
            echo "输入课程信息:"
            read CourseInfo
            echo "$CourseID,$CourseName,$CourseInfo" >>$DBCourserInfoPath
            echo "插入课程内容成功($CourseID,$CourseName,$CourseInfo)"

            #以下是原版的用于绑定的代码
            # echo "请输入负责该课程的教师ID（必须是已有的教师ID）:"
            # read TeacherID
            # while read line; do
            #     CourseID=${line/,*/}
            #     if [ "$CourseID" = "$TeacherID" ]; then
            #         {
            #             export existFlag=true
            #             break
            #         }
            #     fi
            # done <$DBTeacherInfoPath

            # if [ "$existFlag" = "false" ]; then
            #     {
            #         echo "输入的教师工号$TeacherID不存在于教师信息记录文件中($DBTeacherInfoPath)"
            #     }
            # else
            #     {
            #         echo "输入课程信息:"
            #         read CourseInfo
            #         echo "$CourseID,$CourseName,$TeacherID,$CourseInfo" >>$DBCourserInfoPath
            #         echo "插入课程内容成功($CourseID,$CourseName,$TeacherID,$CourseInfo)"
            #     }
            # fi
        }
    fi

}

ChangeCourseInfo() {
    echo "请输入要修改的课程ID："
    read CourseID
    stringLine=$(grep $CourseID $DBCourserInfoPath)
    if [ "$stringLine" != "" ]; then
        {
            CourseName=$(echo "$stringLine" | awk -F',' '{print $2}')
            CourseInfo=$(echo "$stringLine" | awk -F',' '{print $3}')

            echo "要更新的课程信息为:$stringLine"
            echo "输入要更改的信息(1.课程名称 2.课程信息(1 or 2 )):"
            read subCommand
            case $subCommand in
            1)
                echo "请输入课程的新名称： "
                read newCourseName

                sed  "/^$CourseID/d" $DBCourserInfoPath >$DBCourserInfoPath"_back"
                mv -f $DBCourserInfoPath"_back" $DBCourserInfoPath
                echo "$CourseID,$newCourseName,$CourseInfo" >>$DBCourserInfoPath
                echo "更新课程记录成功($CourseID,$newCourseName,$CourseInfo)"
                ;;

            2)
                echo "请输入新课程信息： "
                read newCourseInfo

                sed  "/^$CourseID/d" $DBCourserInfoPath >$DBCourserInfoPath"_back"
                mv -f $DBCourserInfoPath"_back" $DBCourserInfoPath
                echo "$CourseID,$CourseName,$newCourseInfo" >>$DBCourserInfoPath
                echo "更新学生记录成功($CourseID,$CourseName,$newCourseInfo)"
                ;;

            *)
                echo "输入有误，更新失败!"
                ;;
            esac
        }
    else
        {
            echo "不存在该课程ID！"
        }
    fi

}

DeleteCourseInfo() {
    echo "输入要删除的课程ID"
    read CourseID
    export existFlag=false
    export delCount=0
    export delLine=0
    while read line; do
        lineCourseID=${line/,*/}
        if [ "$lineCourseID" = "$CourseID" ]; then
            {
                CourseName=$(echo "$line" | awk -F',' '{print $2}')
                Info=$(echo "$line" | awk -F',' '{print $3}')
                export existFlag=true
                break
            }
        fi
    done <$DBCourserInfoPath
    if [ "$existFlag" = "true" ]; then
        {
            export existFlag=false

            sed "/^$CourseID,$CourseName,$Info/d" $DBCourserInfoPath >$DBCourserInfoPath"_back"
            mv -f $DBCourserInfoPath"_back" $DBCourserInfoPath
            echo "删除课程成功：被删除的课程ID$CourseID"
        }
    else
        {
            echo "课程记录文件中不存在课程ID$CourseID,删除失败"
        }
    fi

}

ListCourseInfo() {
    echo "=================================================="
    echo "课程ID ： 课程名称 ： 课程信息"
    cat $DBCourserInfoPath

}

ChangeCourseInfo_Tea() {
    stringLine=$(grep $1 $DBCourserInfoPath)
    if [ "$stringLine" != "" ]; then
        {
            CourseName=$(echo "$stringLine" | awk -F',' '{print $2}')
            CourseInfo=$(echo "$stringLine" | awk -F',' '{print $3}')

            echo "要更新的课程信息为:$stringLine"
            echo "输入要更改的信息(1.课程名称 2.课程信息(1 or 2 )):"
            read subCommand
            case $subCommand in
            1)
                echo "请输入课程的新名称： "
                read newCourseName

                sed "/^$CourseID/d" $DBCourserInfoPath >$DBCourserInfoPath"_back"
                mv -f $DBCourserInfoPath"_back" $DBCourserInfoPath
                echo "$CourseID,$newCourseName,$CourseInfo" >>$DBCourserInfoPath
                echo "更新课程记录成功($CourseID,$newCourseName,$CourseInfo)"
                ;;

            2)
                echo "请输入新课程信息： "
                read newCourseInfo

                sed "/^$CourseID/d" $DBCourserInfoPath >$DBCourserInfoPath"_back"
                mv -f $DBCourserInfoPath"_back" $DBCourserInfoPath
                echo "$CourseID,$CourseName,$newCourseInfo" >>$DBCourserInfoPath
                echo "更新课程信息成功($CourseID,$CourseName,$newCourseInfo)"
                ;;

            *)
                echo "输入有误，更新失败!"
                ;;
            esac
        }
    else
        {
            echo "不存在该课程ID！"
        }
    fi

}

ListCourseInfo_Tea() {
    stringLine=$(grep $1 $DBCourserInfoPath)
    if [ "$stringLine" != "" ]; then
        {
            CourseName=$(echo "$stringLine" | awk -F',' '{print $2}')
            CourseInfo=$(echo "$stringLine" | awk -F',' '{print $3}')

            echo "课程信息如下："
            echo "课程ID ：课程名称 ：课程信息"
            echo "$1 , $CourseName , $CourseInfo"

        }
    else
        {
            echo "不存在该课程ID或课程中没有学生！"
        }
    fi
}

AddStuToCourse() {
    echo "输入学生ID"
    read StuID

    export existFlag=false
    while read line; do
        lineStuID=${line/,*/}
        if [ "$lineStuID" = "$StuID" ]; then
            {
                StuName=$(echo "$line" | awk -F',' '{print $2}')
                existFlag=true
                break
            }
        fi
    done <$DBStuInfoPath
    if [ "$existFlag" = "false" ]; then
        {
            echo "学生ID不存在！"
            return
        }
    fi
    echo "$1,$StuID,$StuName" >>$DBClassPath
    echo "添加成功，该记录为($1,$StuID,$StuName)"
}

DelStuFromCourse() {
    echo "输入删除的学生ID：（当学生ID不存在时则对数据没有任何影响）"
    read StuID

    sed "/^$1,$StuID/d" $DBClassPath >output
    mv -f output $DBClassPath
    echo "完成删除"

}

ListStuFromCourse() {
    existFlag=true
    while read line; do
        lineCourseID=${line/,*/}
        if [ "$lineCourseID" = "$1" ]; then
            {
                if [ "$existFlag" = "false" ]; then
                    {
                        existFlag=true
                        echo "本课程的学生信息如下："
                        echo "学生ID ： 学生姓名"

                    }
                fi
                StuID=$(echo "$line" | awk -F',' '{print $2}')
                StuName=$(echo "$line" | awk -F',' '{print $3}')
                echo "$StuID,$StuName"
            }
        fi
    done <$DBClassPath

    if [ "$existFlag" = "false" ]; then
        {
            echo "本课程暂未添加学生！"
        }
    fi

}

CreateHomeWork() {
    echo "输入要创建的作业ID（若已存在则创建失败）："
    read HomeWorkID
    export existFlag=false
    while read line; do
        lineHomeWorkID=${line/,*/}
        if [ "$lineHomeWorkID" = "$HomeWorkID" ]; then
            {
                existFlag=true
                break
            }
        fi
    done <$DBHomeWorkPath

    if [ "$existFlag" == "true" ]; then
        {
            export existFlag=false
            echo "作业ID已存在，插入失败"
            return
        }
    fi

    echo "输入作业名称"
    read HomeWorkName
    echo "输入作业类型:"
    echo "HW：作业； Lab：实验"
    read Type
    echo "输入作业要求"
    read Info
    # $1为课程ID
    echo "$HomeWorkID,$1,$HomeWorkName,$Type,$Info" >>$DBHomeWorkPath
    echo "添加成功，该记录为($HomeWorkID,$1,$HomeWorkName,$Type,$Info)"

    #自动创建所有该课程学生的作业完成情况数据
    while read line; do
        lineCourseID=${line/,*/}
        if [ "$lineCourseID" = "$1" ]; then
            {
                StuID=$(echo "$line" | awk -F',' '{print $2}')
                StuName=$(echo "$line" | awk -F',' '{print $3}')
                isFinish=false
                echo "$HomeWorkID,$StuID,$StuName,$isFinish" >>$DBStuHomeWorkPushPath
            }
        fi
    done <$DBClassPath

}

ChangeHomeWork() {
    echo "请输入要修改的作业名称："
    read HWID
    stringLine=$(grep $HWID $DBHomeWorkPath)
    if [ "$stringLine" != "" ]; then
        {
            CourseID=$(echo "$stringLine" | awk -F',' '{print $2}')
            HomeWorkName=$(echo "$stringLine" | awk -F',' '{print $3}')
            Type=$(echo "$stringLine" | awk -F',' '{print $4}')
            Info=$(echo "$stringLine" | awk -F',' '{print $5}')

            echo "要更新的作业信息为:$stringLine"
            echo "输入要更改的信息(1.作业名称 2.类型 3.信息(1 or 2 or 3)):"
            read subCommand
            case $subCommand in
            1)
                echo "请输入作业的新名称："
                read newHomeWorkName

                sed  "/^$HWID/d" $DBHomeWorkPath >$DBHomeWorkPath"_back"
                mv -f $DBHomeWorkPath"_back" $DBHomeWorkPath
                echo "$HWID,$CourseID,$newHomeWorkName,$Type,$Info" >>$DBHomeWorkPath
                echo "更新作业记录成功($HWID,$CourseID,$newHomeWorkName,$Type,$Info)"
                ;;
            2)
                echo "请输入新的作业类型： "
                echo "HW：作业； Lab：实验"
                read newType

                sed  "/^$HWID/d" $DBHomeWorkPath >$DBHomeWorkPath"_back"
                mv -f $DBHomeWorkPath"_back" $DBHomeWorkPath
                echo "$HWID,$CourseID,$HomeWorkName,$newType,$Info" >>$DBHomeWorkPath
                echo "更新作业记录成功($HWID,$CourseID,$HomeWorkName,$newType,$Info)"
                ;;
            3)
                echo "请输入新作业信息： "
                read newInfo

                sed  "/^$HWID/d" $DBHomeWorkPath >$DBHomeWorkPath"_back"
                mv -f $DBHomeWorkPath"_back" $DBHomeWorkPath
                echo "$HWID,$CourseID,$HomeWorkName,$Type,$newInfo" >>$DBHomeWorkPath
                echo "更新作业记录成功($HWID,$CourseID,$HomeWorkName,$Type,$newInfo)"
                ;;

            *)
                echo "输入有误，更新失败!"
                ;;
            esac
        }
    else
        {
            echo "不存在该作业ID！"
        }
    fi

}

DeletHomeWork() {
    echo "输入要删除的作业ID"
    read HWID
    export existFlag=false
    while read line; do
        lineHWID=${line/,*/}
        if [ "$lineHWID" = "$HWID" ]; then
            {
                CourseID=$(echo "$line" | awk -F',' '{print $2}')
                HomeWorkName=$(echo "$line" | awk -F',' '{print $3}')
                Type=$(echo "$line" | awk -F',' '{print $4}')
                Info=$(echo "$line" | awk -F',' '{print $5}')
                export existFlag=true
                break
            }
        fi
    done <$DBHomeWorkPath
    if [ "$existFlag" = "true" ]; then
        {
            sed "/^$HWID,$CourseID,$HomeWorkName,$Type,$Info/d" $DBHomeWorkPath >$DBHomeWorkPath"_back"
            mv -f $DBHomeWorkPath"_back" $DBHomeWorkPath
            #删除学生作业提交记录中的内容
            while read line; do
                lineHWID=${line/,*/}
                if [ "$lineHWID" = "$HWID" ]; then
                    {
                        #Test
                        sed  "/^$HWID/d"  $DBStuHomeWorkPushPath  >$DBStuHomeWorkPushPath"_back"
                        mv -f $DBStuHomeWorkPushPath"_back" $DBStuHomeWorkPushPath
                    }
                fi
            done <$DBStuHomeWorkPushPath

            echo "删除作业成功：被删除的作业ID$HWID"
        }
    else
        {
            echo "作业记录文件中不存在作业ID$HWID,删除失败"
        }
    fi

}

ShowAllHomeWork() {
    echo "=================================================="
    echo "作业ID ： 课程ID ：作业名称 ： 作业类型 ： 作业信息"
    cat $DBHomeWorkPath
}

CheckHomeFinish() {
    echo "输入要查询的作业ID"
    read HomeWorkID
    export existFlag=false
    while read line; do
        lineHWID=${line/,*/}
        if [ "$lineHWID" = "$HomeWorkID" ]; then
            {
                if [ "$existFlag" = "false" ]; then
                    {
                        existFlag=true
                        echo "本作业的完成情况如下："
                        echo "学生ID ： 学生姓名 ： 完成状态"

                    }
                fi
                StuID=$(echo "$line" | awk -F',' '{print $2}')
                StuName=$(echo "$line" | awk -F',' '{print $3}')
                isFinish=$(echo "$line" | awk -F',' '{print $4}')
                echo "$StuID,$StuName,$isFinish"
            }
        fi
    done <$DBStuHomeWorkPushPath
    if [ "$existFlag" = "false" ]; then
        {
            echo "作业ID不存在！"
        }
    fi
}

ShowHW_Stu() {
    export existFlag=false
    while read line; do
        StuID=$(echo "$line" | awk -F',' '{print $2}')
        if [ "$StuID" = "$1" ]; then
            {
                if [ "$existFlag" = "false" ]; then
                    {
                        existFlag=true
                        echo "您当前的作业信息如下："
                        echo "作业ID,作业名称，作业类型，作业信息，完成状态"

                    }
                fi
                HWID=$(echo "$line" | awk -F',' '{print $1}')
                State=$(echo "$line" | awk -F',' '{print $4}')

                stringLine=$(grep $HWID $DBHomeWorkPath)
                HomeWorkName=$(echo "$stringLine" | awk -F',' '{print $3}')
                Type=$(echo "$stringLine" | awk -F',' '{print $4}')
                Info=$(echo "$stringLine" | awk -F',' '{print $5}')

                echo "$HWID,$HomeWorkName,$Type,$Info,$State"
            }
        fi
    done <$DBStuHomeWorkPushPath

    if [ "$existFlag" = "false" ]; then
        {
            echo "您当前没有这一项作业！"
        }
    fi

}

ChangeHW_Stu() {
    echo "输入您要修改的作业ID"
    read HWID
    export existFlag=false

    line=$(grep "$HWID,$1" $DBStuHomeWorkPushPath)
    if [ "$line" != "" ]; then
        {
            existFlag=true
            StuName=$(echo "$line" | awk -F',' '{print $3}')
            echo "您正在修改的作业信息如下："
            echo "$line"
            read -p "您要将当前作业的状态修改为:（true or false)" newStatus

            sed  "/^$HWID,$1/d" $DBStuHomeWorkPushPath >$DBStuHomeWorkPushPath"_back"
            mv -f $DBStuHomeWorkPushPath"_back" $DBStuHomeWorkPushPath
            echo "$HWID,$StuID,$StuName,$newStatus" >>$DBStuHomeWorkPushPath
            echo "更新作业状态成功($HWID,$StuID,$StuName,$newStatus)"
        }
    fi

    if [ "$existFlag" = "false" ]; then
        {
            echo "您当前没有这一项作业！"
        }
    fi

}

administratorUI() {
    while true; do
        echo " "
        echo "===============欢迎进入管理员界面==============="
        echo "===============选择你要进行的操作==============="
        echo "0.退出学生管理系统"
        echo "1.创建教师信息"
        echo "2.删除教师信息"
        echo "3.修改教师信息"
        echo "4.显示教师信息"
        echo "5.创建课程信息"
        echo "6.修改课程信息"
        echo "7.删除课程信息"
        echo "8.显示课程信息"
        echo "9.创建学生信息"
        echo "10.删除学生信息"
        echo "11.修改学生信息"
        echo "12.显示学生信息"
        echo "13.绑定课程与教师"
        echo "14.解绑课程与教师"
        echo "15.显示课程绑定关系"
        echo "16.返回上一层菜单"
        read iCommand
        case $iCommand in
        0)
            echo "已经安全退出系统."
            exit 0
            ;;
        1)
            InsertTeacherInfo
            ;;
        2)
            DeleteTeacherInfo
            ;;
        3)
            ChangeTeacherInfo
            ;;
        4)
            ListTeacherInfo
            ;;
        5)
            InsertCourseInfo
            ;;
        6)
            ChangeCourseInfo
            ;;
        7)
            DeleteCourseInfo
            ;;
        8)
            ListCourseInfo
            ;;
        9)
            InsertStuInfo
            ;;
        10)
            DeleteStuInfo
            ;;
        11)
            ChangeStuInfo
            ;;
        12)
            ListStuInfo
            ;;
        13)
            connect_teacher_course
            ;;
        14)
            disconnect_teacher_course
            ;;
        15)
            List_teacher_course
            ;;
        16)
            return
            ;;
        *)
            echo "超出可选择的指令！"
            ;;
        esac

    done
}

TeacherUI() {
    echo "请输入教工工号："
    read teacherID
    #获取教师账户所在的行
    stringLine=$(grep $teacherID $DBTeacherInfoPath)
    if [ "$stringLine" != "" ]; then
        {
             #获取正确的密码
            PassWord=$(echo "$stringLine" | awk -F',' '{print $4}')
            echo "请输入教工工号对应的密码"
            read iPassWord
            #比较
            if [ "$iPassWord" = "$PassWord" ]; then
                {
                    echo "密码正确，正在进人教师界面"
                }
            else
                {
                    echo "密码错误！"
                    return
                }
            fi

        }
    else
        {
            echo "不存在该教工工号"
            return
        }
    fi

    echo "您当前绑定的课程ID如下："
    export existFlag=false
    #在DBTeacher_CoursePath中查询与教师ID绑定的课程ID，并显示
    while read line; do
        lineTeacherID=${line/,*/}
        if [ "$lineTeacherID" = "$teacherID" ]; then
            {
                existFlag=true
                #awk确定课程ID
                CourseID=$(echo "$line" | awk -F',' '{print $2}')
                echo "$CourseID"
                break
            }
        fi
    done <$DBTeacher_CoursePath

    #如果没有发现教师绑定任何课程则退出当前界面
    if [ "$existFlag" = "false" ]; then
        {
            echo "您当前未绑定到任何课程，请联系管理员！"
            return
        }
    fi

    declare opCourseID
    #反复输入课程ID直到输入正确为止，由于进入到这一步必定存在绑定的课程
    while true; do
        echo "请选择您要操作的课程（输入课程ID）"
        read opCourseID
        #用教师ID和课程ID来唯一确定绑定关系
        Tuple="$teacherID,$opCourseID"
        existFlag=false
        while read line; do
            if [ "$line" = "$Tuple" ]; then
                {
                    existFlag=true
                    break
                }
            fi
        done <$DBTeacher_CoursePath

        if [ "$existFlag" = "false" ]; then
            {
                echo "该课程不存在或您未绑定到该课程！"
            }
        else
            {
                echo "已查询到您账户下的该课程，正在进入课程管理界面"
                break
            }
        fi
    done
    
    #正式进入操作界面
    while true; do
        echo " "
        echo "===============欢迎进入教师界面==============="
        echo "您的工号为$teacherID,当前课程ID为$opCourseID"
        echo "===============选择你要进行的操作==============="
        echo "0.退出管理系统"
        echo "1.修改课程信息"
        echo "2.显示课程信息"
        echo "3.新建作业/实验"
        echo "4.修改作业/实验"
        echo "5.删除作业/实验"
        echo "6.显示作业/实验"
        echo "7.向本课程中添加学生"
        echo "8.删除本课程中学生"
        echo "9.显示本课程中学生"
        echo "10.查询学生作业完成情况"
        echo "11.返回上一层菜单"
        read iCommand
        case $iCommand in
        0)
            echo "已经安全退出系统."
            exit 0
            ;;
        1)
            #TODO
            ChangeCourseInfo_Tea "$opCourseID"
            ;;
        2)
            ListCourseInfo_Tea "$opCourseID"
            ;;
        3)
            CreateHomeWork "$opCourseID"
            ;;

        4)
            ChangeHomeWork

            ;;

        5)
            DeletHomeWork
            ;;

        6)
            ShowAllHomeWork
            ;;

        7)
            AddStuToCourse "$opCourseID"
            ;;
        8)
            DelStuFromCourse "$opCourseID"
            ;;

        9)
            ListStuFromCourse "$opCourseID"
            ;;
        10)

            CheckHomeFinish
            ;;
        11)
            return
            ;;
        *)
            echo "超出可选择的指令！"
            ;;

        esac

    done

}

StuUI() {
    echo "请输入学号："
    read StuID
    stringLine=$(grep $StuID $DBStuInfoPath)
    if [ "$stringLine" != "" ]; then
        {
            PassWord=$(echo "$stringLine" | awk -F',' '{print $4}')
            echo "请输入学号对应的密码"
            read iPassWord
            if [ "$iPassWord" = "$PassWord" ]; then
                {
                    echo "密码正确，正在进人学生界面"
                }
            else
                {
                    echo "密码错误！"
                    return
                }
            fi

        }
    else
        {
            echo "不存在该学生ID"
            return
        }
    fi

    while true; do
        echo "===============欢迎进入学生界面==============="
        echo "您的学号为$StuID"

        echo "===============选择你要进行的操作==============="
        echo "0. 退出学生管理系统"
        echo "1. 查询自己当前作业/实验情况"
        echo "2. 修改作业/实验状态"
        echo "3. 退回到上一层菜单"

        read iCommand
        case $iCommand in
        0)
            echo "已经安全退出系统."
            exit 0
            ;;
        1)
            ShowHW_Stu "$StuID"
            ;;
        2)
            ChangeHW_Stu "$StuID"
            ;;
        3)
            return
            ;;
        *)
            echo "超出可选择的指令！"
            ;;

        esac
    done

}

echo " "
echo "===============欢迎进入学生作业管理系统==============="
while true; do
    echo "===============选择你的登录方式==============="
    echo "0.退出学生管理系统"
    echo "1.以管理员身份登录"
    echo "2.以教师身份登录"
    echo "3.以学生身份登录"
    echo "输入command:"
    read iCommand
    case $iCommand in
    0)
        echo "已经安全退出系统."
        exit 0
        ;;
    1)
        administratorID="20200202"
        echo "请输入管理员ID号"
        read ID_1
        if [[ "$ID_1" = "$administratorID" ]]; then
            echo "ID号正确，正在进入管理员界面！"
            administratorUI
        else
            echo "ID号错误！"
        fi
        ;;
    2)
        TeacherUI
        ;;
    3)
        StuUI
        ;;
    *)
        echo "超出可选择的指令！"
        ;;

    esac

done

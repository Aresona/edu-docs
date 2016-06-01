# Git学习记录

[廖雪峰Git](http://www.liaoxuefeng.com/wiki/0013739516305929606dd18361248578c67b8067c8c017b000)

##概念
**工作区（Working Directory）**

就是你在电脑里能看到的目录，比如我的learngit文件夹就是一个工作区：

**版本库（Repository）**

工作区有一个隐藏目录.git，这个不算工作区，而是Git的版本库。

Git的版本库里存了很多东西，其中最重要的就是称为stage（或者叫index）的暂存区，还有Git为我们自动创建的第一个分支master，以及指向master的一个指针叫HEAD。

##一般操作
**初始化仓库**
<pre>
$ mkdir learngit
$ cd learngit
$ pwd
/Users/michael/learngit
$ git init
</pre>

**添加文件到版本库**

    git add readme.txt
> 版本库其实指的是.git目录

> 工作区指的就是 `git init` 的那个目录

**撤销版本库中的添加的文件**

    git rm --cached readme.txt


**提交文件到仓库**

    git commit -m "wrote a readme file"
**查看仓库当前状态**

    git status

**查看修改内容**

    git diff readme.txt 

**提交历史记录**

    git log
    git log --pretty=oneline

**版本回退**

    $ git reset --hard HEAD^
**曾经操作过的日志**
    git reflog
> 这个命令可以配合git reset --hard命令来回退版本（在git中，总有后悔药可以吃）

**丢弃工作区的修改**

    git checkout -- <file>
	git checkout -- readme.txt

> 命令git checkout -- readme.txt意思就是，把readme.txt文件在工作区的修改全部撤销，这里有两种情况：

> 一种是readme.txt自修改后还没有被放到暂存区，现在，撤销修改就回到和版本库一模一样的状态；

> 一种是readme.txt已经添加到暂存区后，又作了修改，现在，撤销修改就回到添加到暂存区后的状态。

> 总之，就是让这个文件回到最近一次git commit或git add时的状态。

	git checkout -- file命令中的--很重要，没有--，就变成了“切换到另一个分支”的命令，我们在后面的分支管理中会再次遇到git checkout命令。

**撤销掉（unstage）暂存区的修改，重新放回工作区：**

	git reset HEAD file

`git reset` 命令既可以回退版本，也可以把暂存区的修改回退到工作区。当我们用 `HEAD` 时，表示最新的版本。

**删除**

    rm         Remove files from the working tree and from the index

    git rm test.txt
## Git远程仓库

### 添加本地账户到GitHub

只要注册一个GitHub账号，就可以免费获得Git远程仓库

* 创建SSH Key
<pre>
$ ssh-keygen -t rsa -C "2514826467@qq.com"
Generating public/private rsa key pair.
Enter file in which to save the key (/c/Users/Administrator/.ssh/id_rsa):
Created directory '/c/Users/Administrator/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /c/Users/Administrator/.ssh/id_rsa.
Your public key has been saved in /c/Users/Administrator/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:LW0H9A+PkOzpo5cLg8/vJY8xx4jmG8z2bS6ds1ULtoI 2514826467@qq.com
The key's randomart image is:
+---[RSA 2048]----+
|          .      |
|         o o     |
|          = o    |
|         + + =   |
|        S * ooo .|
|       + =.+. o..|
|      . XEB++o.. |
|       * *+@*.   |
|        *=*==o   |
+----[SHA256]-----+
</pre>


> 这里无需设置密码，它说的是密钥的密码

* 添加公钥到GitHub上

Setting--> SSH and GPG Keys --> New SSH Key --> 填入标题及公钥内容 --> Add SSH Key --> 这时会收到一份GitHub的邮件
<pre>
The following SSH key was added to your account:

Ares
08:54:63:2c:01:a1:78:59:ff:97:c5:08:25:d4:45:b8

If you believe this key was added in error, you can remove the key and disable
access at the following location:

https://github.com/settings/ssh
</pre>
> 为什么GitHub需要SSH Key呢？因为GitHub需要识别出你推送的提交确实是你推送的，而不是别人冒充的

### 添加并关联远程库
现在的情景是，你已经在本地创建了一个Git仓库后，又想在GitHub创建一个Git仓库，并且让这两个仓库进行远程同步，这样，GitHub上的仓库既可以作为备份，又可以让其他人通过该仓库来协作，真是一举多得。

加号 --> New Repository --> 加入名字保持默认

<pre>
$ cd /e/MyGit
$ git remote add origin git@github.com:Aresona/edu-docs.git
$ git push -u origin master
The authenticity of host 'github.com (192.30.252.129)' can't be established.
RSA key fingerprint is SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCRLviKwE5SY8.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'github.com,192.30.252.129' (RSA) to the list of known hosts.
Counting objects: 3, done.
Writing objects: 100% (3/3), 243 bytes | 0 bytes/s, done.
Total 3 (delta 0), reused 0 (delta 0)
To git@github.com:Aresona/edu-docs.git
 * [new branch]      master -> master
Branch master set up to track remote branch master from origin.

</pre>

### 克隆远程库

* 创建远程库

<pre>
New Repository --> Initialize this repository with a README 
</pre>

* 克隆远程库到本地工作区
<pre>
git clone git@github.com:Aresona/GIt.git
</pre>


## 分支管理

### 概念

##### 分支

1. 不只是HEAD是一个指针，master和dev也是一个指针，它们的对应关系是：HEAD指向分支指针，而分去指针又指向最新的提交。
2. 当新增一个分去的时候，其实是新创建一个分支指针，然后把HEAD指针指向这个指针，工作区内容不变，所以在GIT下创建一个分支非常简单。
3. 当有一个新的提交的时候，分支指针就会指向最新的提交，也就是说向前移一步，相应地HEAD指针也就向前移一步。

##### 合并

1. 合并的时候工作区的内容也不会变化，同样也是指针在变化
2. 合并就是直接把master指向dev的当前提交，就完成了合并：

### 解决冲突

> 个人理解：如果在master分支上另外创建分支，然后在建立分支的节点上合并的时候是不会发生冲突的，只有在master分支也commit后才可能会发生冲突。

> 在git merge dev的时候，git会把所有冲突的东西都放在那个文件里面，我们需要做的就是把里面的东西修改掉，最低的标准就是把那些>>><<<==之类的去掉

**禁用Fast-Forward合并模式**

    git merge --no-ff -m "merge with no-ff" dev

**不使用Fast-Foward模式来合并图**

![](http://www.liaoxuefeng.com/files/attachments/001384909222841acf964ec9e6a4629a35a7a30588281bb000/0)

**使用Fast-Forward模式合并图**

![](http://www.liaoxuefeng.com/files/attachments/00138490883510324231a837e5d4aee844d3e4692ba50f5000/0)

**解决冲突后的合并图**

![](http://www.liaoxuefeng.com/files/attachments/00138490913052149c4b2cd9702422aa387ac024943921b000/0)

#### 分支管理策略

在实际开发中，我们应该按照几个基本原则进行分支管理 ：

首先，master分支应该是非常稳定的，也就是仅用来发布新版本，平时不能在上面干活；

那在哪干活呢？干活都在dev分支上，也就是说，dev分支是不稳定的，到某个时候，比如1.0版本发布时，再把dev分支合并到master上，在master分支发布1.0版本；

你和你的小伙伴们每个人都在dev分支上干活，每个人都有自己的分支，时不时地往dev分支上合并就可以了。

所以，团队合作的分支看起来就像这样：

![](http://www.liaoxuefeng.com/files/attachments/001384909239390d355eb07d9d64305b6322aaf4edac1e3000/0)

#### Bug分支相关

> 它的要点就是bug需要紧急处理的时候需要切分支，这时就需要一个从容的方法

**存储工作现场**

    git stash

**查看存储列表**

	git stash list

**恢复工作区**

* 用 `git stash apply` 恢复，但恢复后，stash内容并不删除，需要 `git stash drop` 手动删除 
* 用 `git stash pop` ，恢复的同时把stash内容也删了；
* 用 `git stash apply stash@{0}`来恢复指定的stash

#### reature分支相关

> feature分支的特殊之处就是在有些功能可能在开发一半后就不需要了，这时使用 `git branch -d feature` 的时候是删除不掉的，它会提示使用命令 `git branch -D feature` 来删除。

#### 多人协作相关

查看远程库的信息，用 `git remote`

用 `git remote -v` 显示更详细的信息，*如果没有推送权限，就看不到push的地址*

推送分支，就是把该分支上的所有本地提交推送到远程库。推送时，要指定本地分支，这样，Git就会把该分支推送到远程库对应的远程分支上；


#### 小结

Git鼓励大量使用分支：

查看分支：`git branch`

创建分支：`git branch <name>`

切换分支：`git checkout <name>`

创建+切换分支：`git checkout -b <name>`

合并某分支到当前分支：`git merge <name>`

删除分支：`git branch -d <name>`

查看分支合并图： `git log --graph` 或 `git log --graph --pretty=oneline` 或 `git log --graph --abbrev-commit`


## 场景演练
场景1：当你改乱了工作区某个文件的内容，想直接丢弃工作区的修改时，用命令git checkout -- file。

场景2：当你不但改乱了工作区某个文件的内容，还添加到了暂存区时，想丢弃修改，分两步，第一步用命令git reset HEAD file，就回到了场景1，第二步按场景1操作。

场景3：已经提交了不合适的修改到版本库时，想要撤销本次提交，参考版本回退一节，不过前提是没有推送到远程库。


###生疏操作



小结


* 初始化一个Git仓库，使用git init命令。

* 添加文件到Git仓库，分两步：

		第一步，使用命令git add <file>，注意，可反复多次使用，添加多个文件；

		第二步，使用命令git commit，完成。

* 要随时掌握工作区的状态，使用git status命令。

* 如果 `git status` 告诉你有文件被修改过，用 `git diff` 可以查看修改内容。

* HEAD指向的版本就是当前版本，因此，Git允许我们在版本的历史之间穿梭，使用命令 `git reset --hard commit_id` 。

* 穿梭前，用 `git log` 可以查看提交历史，以便确定要回退到哪个版本。

* 要重返未来，用 `git reflog` 查看命令历史，以便确定要回到未来的哪个版本。

* `git add` 命令跟 `git commit` 命令的区别及联系

   
>  git add命令实际上就是把要提交的所有修改放到暂存区（Stage），然后，执行git commit就可以一次性把暂存区的所有修改提交到分支。

* .git里面的内容

**图解**

![](http://www.liaoxuefeng.com/files/attachments/001384907702917346729e9afbf4127b6dfbae9207af016000/0)

[版本库理解](http://www.liaoxuefeng.com/wiki/0013739516305929606dd18361248578c67b8067c8c017b000/0013745374151782eb658c5a5ca454eaa451661275886c6000)

* Git是如何跟踪修改的，每次修改，如果不add到暂存区，那就不会加入到commit中
* 

# thingymodulecreate - commandline tool to add a thingyModule inside a thingy

# Why?
After having created a thingy one usually wants to refactor the structure again at any time.

This tool is for this purpose.

Fine grained codesharing for the win!
And dare to change your mind on the road ;-)

# What?
This is a small helper tool which executes a specific instruction line in the same way a recipe would provide it after the user has clarified the ambiguity.

It uses the current working directory as base and even may transform directories to submodules and vice versa.

It is thought to be be called inside your build system to conveniently adjust what code from where in which relation you use. In the specific way what fits your workflow in your build system.

# How?

This tool uses the `userConfig` from thingycreate to access the `cloudServices` to which you have access to.

Requirements
------------
* [GitHub account](https://github.com/) and/or [Gitlab account](https://gitlab.com/)
* [GitHub ssh-key access](https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and/or [Gitlab ssh-key-access](https://docs.gitlab.com/ee/gitlab-basics/create-your-ssh-keys.html)
* [GitHub access token (repo scope)](https://github.com/settings/tokens) and/or [Gitlab access token (api scope)](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)
* [Git installed](https://git-scm.com/)
* [Node.js installed](https://nodejs.org/)

Installation
------------

Current git version
``` sh
$ npm install -g git+https://gitlab.com/lenny09918050/thingymodulecreate-output.git
```
Npm Registry
``` sh
$ npm install -g thingymodulecreate
```


Usage
-----

For most usecases it is necessary that you have your ssh-key usable in your shell. I personally add it using the [ssh-agent](https://www.ssh.com/ssh/agent) right before I start developing anyways.


```
 Usage
      $ thingymodulecreate <arg1>
    
  Options
      required:
          arg1, --instruction <instruction-line>, -i <instruction-line>
              instructionLine (construction instruction for a thingyModule)
      optional: 
          --configure, -c
              flag to start user configuration

  TO NOTE:
      The flags will overwrite the flagless argument.

  Examples
      $ thingymodulecreate submodule,networkmanagermodule,create,sourcessourcemodule
      ...
```
The `instructionLine` is string where tokens are separated by commas.
These tokens represent the unambiguous result how a thingymodule is being constructed. In the same way as we get it from our recipes.

A better description about how these recipes work consider taking a look at [thingycreate/recipes](https://www.npmjs.com/package/thingycreate#thingytype---recipe).

Current Functionality
---------------------

- add `thingyModule` create,merge,use (as submodule or directory) 
- transform directory to submodule
- transform submodule to directory

### All Possibilities for valid `instructionLines`:

- #### directory,directory-name,use,repository-name
    This will clone the `repository-name` from your `globalScope` to your `defaultThingyRoot` from your `userConfig.json` and then create a symlink onto it.

- #### directory,directory-name,merge,repository-name
    This will copy the contents of `repository-name` from your `globalScope` into a newly created directory at `cwd/directory-name`.

- #### directory,directory-name,create,thinyModuleType
    This will execute the recipe `thingyModuleType-recipe` and copy it's contents into the newly created directory at `cwd/directory-name`.

- #### submodule,directory-name,use,repository-name
    This will add `repository-name` from your `globalScope` as submodule on `cwd/directory-name`.

- #### submodule,directory-name,merge,repository-name
    This will copy the contents of `repository-name` from your `globalScope` into a newly created repository which then is added as submodule to `cwd/directory-name`. The newly created repository will be named `parentThingyName-directory-name`.

- #### submodule,directory-name,create,thinyModuleType
    This will execute the recipe `thingyModuleType-recipe` and create a new repository which is then added as submodule to `cwd/directory-name`.The newly created repository will be named `parentThingyName-directory-name`.

- #### submodule,directory-name
    This will transform the directory at `cwd/directory-name` into a submodule creating a new repository named `parentThingyName-directory-name`.

- ### directory,directory-name
    This will transform the submodule at `cwd/directory-name` into a directory all versioning stuff is removed.

## userConfig
The `userConfig` works in the same way as in [thingycreate](https://npmjs.com/package/thingycreate).



# Further steps
Ideas of what could come next:

- connect shared code as thought with thingycontrol and thingycreate
- handle annoying common usag errors to give nice hints
- clean out some code
- ...


All sorts of inputs are welcome, thanks!

---

# License

## The Unlicense JhonnyJason style

- Information has no ownership.
- Information only has memory to reside in and relations to be meaningful.
- Information cannot be stolen. Only shared or destroyed.

And you wish it has been shared before it is destroyed.

The one claiming copyright or intellectual property either is really evil or probably has some insecurity issues which makes him blind to the fact that he also just connected information which was freely available to him.

The value is not in him who "created" the information the value is what is being done with the information.
So the restriction and friction of the informations' usage is exclusively reducing value overall.

The only preceived "value" gained due to restriction is actually very similar to the concept of blackmail (power gradient, control and dependency).

The real problems to solve are all in the "reward/credit" system and not the information distribution. Too much value is wasted because of not solving the right problem.

I can only contribute in that way - none of the information is "mine" everything I "learned" I actually also copied.
I only connect things to have something I feel is missing and share what I consider useful. So please use it without any second thought and please also share whatever could be useful for others. 

I also could give credits to all my sources - instead I use the freedom and moment of creativity which lives therein to declare my opinion on the situation. 

*Unity through Intelligence.*

We cannot subordinate us to the suboptimal dynamic we are spawned in, just because power is actually driving all things around us.
In the end a distributed network of intelligence where all information is transparently shared in the way that everyone has direct access to what he needs right now is more powerful than any brute power lever.

The same for our programs as for us.

It also is peaceful, helpful, friendly - decent. How it should be, because it's the most optimal solution for us human beings to learn, to connect to develop and evolve - not being excluded, let hanging and destroy oneself or others.

If we really manage to build an real AI which is far superior to us it will unify with this network of intelligence.
We never have to fear superior intelligence, because it's just the better engine connecting information to be most understandable/usable for the other part of the intelligence network.

The only thing to fear is a disconnected unit without a sufficient network of intelligence on its own, filled with fear, hate or hunger while being very powerful. That unit needs to learn and connect to develop and evolve then.

We can always just give information and hints :-) The unit needs to learn by and connect itself.

Have a nice day! :D
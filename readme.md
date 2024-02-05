# Data converter

An experiment to convert data from one format to another using OpenAI and XProc. Here as an example YAML → JSON.

## Usage

1. Create an assistant on [OpenAi platform](https://platform.openai.com/assistants). (It is also possible via XProc, but easier this way).

    **Instructions**

    You are an expert in the field of data conversion in the IT sector. Your task is to convert from YAML format to JSON format. Use for this task the Code Interpreter tool. Use the PyYAML and json package for the conversion. Use the option "ensure_ascii=False" for the json.dump() method. It is very important that no properties in YAML format are lost during this conversion and that the data is transferred to JSON format without any losses. The result is returned in JSON format. DO NOT add a description, explanation or marker in your answer and only output the converted json result. Take your time for this task and follow the instructions carefully step by step.

    **Model**

    gpt-3.5-turbo-1106 or gpt-4-1106-preview
    
    **Tools**
   
    Code interpreter: on

3. Add the API key in the file `lib.xpl` (line 30) and the ID for the created assistant in the file `data-converter.xpl` (line 30)
4. Start the pipeline. (I used [MorganaXProc-IIIse-1.3](https://www.xml-project.com/))


**Please note:** This is only an experiment and is not intended for production use.

## Learnings

on [Mastodon](https://mastodon.social/@rolanddreger/111772817903365478)

## ToDo's

One thing did not work: The upload of files using form-data via XProc: [Question on stackoverflow](
https://stackoverflow.com/questions/77874715/xproc-3-form-data-with-file) If anyone has an answer to this, please let me know! 

# License

[MIT](http://www.opensource.org/licenses/mit-license.php)
